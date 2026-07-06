import { existsSync, realpathSync } from "node:fs";
import readline from "node:readline";
import path from "node:path";
import { pathToFileURL } from "node:url";

function resolveCspellLibModule(cspellCommand) {
  const resolvedCommand = realpathSync(cspellCommand);
  const packageRoot =
    path.basename(resolvedCommand) === "bin.mjs"
      ? path.dirname(resolvedCommand)
      : path.dirname(path.dirname(resolvedCommand));
  const modulePath = path.join(
    packageRoot,
    "node_modules",
    "cspell-lib",
    "dist",
    "lib",
    "index.js",
  );

  if (!existsSync(modulePath)) {
    throw new Error(`Unable to locate bundled cspell-lib from ${cspellCommand}`);
  }

  return pathToFileURL(modulePath).href;
}

function normalizeSuggestions(issue) {
  if (Array.isArray(issue.suggestionsEx) && issue.suggestionsEx.length) {
    return issue.suggestionsEx.map(
      (item) => item.wordAdjustedToMatchCase || item.word,
    );
  }
  if (Array.isArray(issue.suggestions)) {
    return issue.suggestions.slice();
  }
  return [];
}

function normalizeIssue(issue) {
  return {
    text: issue.text,
    offset: issue.offset,
    length: issue.length,
    issueType: issue.isFlagged ? "Forbidden word" : "Unknown word",
    isFlagged: Boolean(issue.isFlagged),
    suggestions: normalizeSuggestions(issue),
  };
}

const moduleCache = new Map();

async function getCspellApi(cspellCommand) {
  const moduleUrl = resolveCspellLibModule(cspellCommand);

  if (!moduleCache.has(moduleUrl)) {
    moduleCache.set(moduleUrl, import(moduleUrl));
  }

  return moduleCache.get(moduleUrl);
}

async function handleRequest(request) {
  const {
    requestId = null,
    cspellCommand,
    uri,
    text,
    baseOffset = 0,
    languageId,
    locale,
    configFile,
    root,
  } = request;

  if (!cspellCommand) {
    throw new Error("Missing cspellCommand");
  }
  if (typeof uri !== "string" || typeof text !== "string") {
    throw new Error("Request must include string uri and text");
  }

  if (root) {
    process.chdir(root);
  }

  const { fileToDocument, spellCheckDocumentRPC } = await getCspellApi(cspellCommand);
  const document = fileToDocument(uri, text, languageId, locale);
  const result = await spellCheckDocumentRPC(
    document,
    {
      configFile,
      generateSuggestions: true,
      noConfigSearch: false,
    },
    {
      loadDefaultConfiguration: true,
    },
  );

  return {
    requestId,
    issues: (result.issues || []).map((issue) => {
      const normalized = normalizeIssue(issue);
      normalized.offset += baseOffset;
      return normalized;
    }),
    checked: Boolean(result.checked),
    errors: (result.errors || []).map((error) => error.message || String(error)),
  };
}

function writeResponse(response) {
  process.stdout.write(`${JSON.stringify(response)}\n`);
}

function writeCanceledResponse(requestId) {
  writeResponse({
    requestId,
    canceled: true,
    issues: [],
    checked: false,
    errors: [],
  });
}

async function runOnce() {
  const chunks = [];

  for await (const chunk of process.stdin) {
    chunks.push(chunk);
  }

  const request = JSON.parse(Buffer.concat(chunks).toString("utf8"));
  writeResponse(await handleRequest(request));
}

async function runServer() {
  const canceled = new Set();
  const queue = [];
  let activeRequestId = null;

  function removeQueuedRequest(requestId) {
    const index = queue.findIndex((item) => item.requestId === requestId);
    if (index >= 0) {
      queue.splice(index, 1);
      return true;
    }
    return false;
  }

  function replaceQueuedRequest(request) {
    const index = queue.findIndex((item) => item.uri === request.uri);
    if (index >= 0) {
      const old = queue[index];
      queue[index] = request;
      writeCanceledResponse(old.requestId);
      return true;
    }
    return false;
  }

  async function pumpQueue() {
    if (activeRequestId !== null || queue.length === 0) {
      return;
    }

    const request = queue.shift();
    activeRequestId = request.requestId;

    try {
      const response = await handleRequest(request);
      if (canceled.delete(request.requestId)) {
        writeCanceledResponse(request.requestId);
      } else {
        writeResponse(response);
      }
    } catch (error) {
      if (canceled.delete(request.requestId)) {
        writeCanceledResponse(request.requestId);
      } else {
        writeResponse({
          requestId: request?.requestId ?? null,
          issues: [],
          checked: false,
          errors: [error.message || String(error)],
        });
      }
    } finally {
      activeRequestId = null;
      void pumpQueue();
    }
  }

  const rl = readline.createInterface({
    input: process.stdin,
    crlfDelay: Infinity,
  });

  rl.on("line", (line) => {
    if (!line.trim()) {
      return;
    }

    let message;

    try {
      message = JSON.parse(line);
    } catch (error) {
      writeResponse({
        requestId: null,
        issues: [],
        checked: false,
        errors: [error.message || String(error)],
      });
      return;
    }

    if (message.type === "cancel") {
      const { requestId } = message;
      if (removeQueuedRequest(requestId)) {
        writeCanceledResponse(requestId);
        return;
      }
      if (activeRequestId === requestId) {
        canceled.add(requestId);
      }
      return;
    }

    if (canceled.delete(message.requestId)) {
      writeCanceledResponse(message.requestId);
      return;
    }

    if (!replaceQueuedRequest(message)) {
      queue.push(message);
    }
    void pumpQueue();
  });

  await new Promise((resolve) => rl.once("close", resolve));
}

async function main() {
  if (process.argv.includes("--once")) {
    await runOnce();
    return;
  }

  await runServer();
}

main().catch((error) => {
  const message =
    error && typeof error === "object" && "stack" in error
      ? error.stack
      : String(error);
  process.stderr.write(`${message}\n`);
  process.exitCode = 1;
});
