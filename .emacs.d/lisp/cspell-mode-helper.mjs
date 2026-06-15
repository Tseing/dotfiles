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
    issues: (result.issues || []).map(normalizeIssue),
    checked: Boolean(result.checked),
    errors: (result.errors || []).map((error) => error.message || String(error)),
  };
}

function writeResponse(response) {
  process.stdout.write(`${JSON.stringify(response)}\n`);
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
  const rl = readline.createInterface({
    input: process.stdin,
    crlfDelay: Infinity,
  });

  for await (const line of rl) {
    if (!line.trim()) {
      continue;
    }

    let request;

    try {
      request = JSON.parse(line);
      writeResponse(await handleRequest(request));
    } catch (error) {
      writeResponse({
        requestId: request?.requestId ?? null,
        issues: [],
        checked: false,
        errors: [error.message || String(error)],
      });
    }
  }
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
