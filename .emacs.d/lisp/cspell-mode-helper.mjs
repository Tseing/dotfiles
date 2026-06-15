import { existsSync, realpathSync } from "node:fs";
import path from "node:path";
import { pathToFileURL } from "node:url";

function readStdin() {
  return new Promise((resolve, reject) => {
    const chunks = [];
    process.stdin.on("data", (chunk) => chunks.push(chunk));
    process.stdin.on("end", () => resolve(Buffer.concat(chunks).toString("utf8")));
    process.stdin.on("error", reject);
  });
}

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

async function main() {
  const raw = await readStdin();
  const request = JSON.parse(raw);
  const { cspellCommand, uri, text, languageId, locale, configFile, root } = request;

  if (!cspellCommand) {
    throw new Error("Missing cspellCommand");
  }
  if (typeof uri !== "string" || typeof text !== "string") {
    throw new Error("Request must include string uri and text");
  }

  if (root) {
    process.chdir(root);
  }

  const moduleUrl = resolveCspellLibModule(cspellCommand);
  const { fileToDocument, spellCheckDocumentRPC } = await import(moduleUrl);
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

  const response = {
    issues: (result.issues || []).map(normalizeIssue),
    checked: Boolean(result.checked),
    errors: (result.errors || []).map((error) => error.message || String(error)),
  };

  process.stdout.write(`${JSON.stringify(response)}\n`);
}

main().catch((error) => {
  const message =
    error && typeof error === "object" && "stack" in error
      ? error.stack
      : String(error);
  process.stderr.write(`${message}\n`);
  process.exitCode = 1;
});
