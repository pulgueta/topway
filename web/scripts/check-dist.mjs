// Examines the build in dist/ before a deploy. A deploy to Workers Static Assets replaces all
// the files of the site, so a build without these files stops the sign-in of Topway or the
// updates of the direct build. The script stops with an error when a file is missing or wrong.
//
// Usage: node scripts/check-dist.mjs (npm run build runs it after astro build)

import { existsSync, readFileSync } from "node:fs";
import { fileURLToPath } from "node:url";

const web = new URL("../", import.meta.url);
const dist = new URL("dist/", web);
const source = new URL("public/", web);

const AASA_PATH = ".well-known/apple-app-site-association";
// The Associated Domains file of the sign-in callback, byte for byte. AGENTS.md, "Sign-in
// callback", tells why it must not change.
const AASA_BYTES = '{"webcredentials":{"apps":["7QNFW3929Z.com.pulgueta.topway"]}}\n';
const CALLBACK_PATH = "oauth/callback.html";
const APPCAST_PATH = "appcast.xml";

const errors = [];

function read(base, path) {
  const url = new URL(path, base);
  return existsSync(url) ? readFileSync(url) : null;
}

function check(condition, message) {
  if (!condition) errors.push(message);
  return condition;
}

// 1. The Associated Domains file has the exact bytes.
const aasa = read(dist, AASA_PATH);
if (check(aasa !== null, `dist/${AASA_PATH} is missing.`)) {
  check(
    aasa.equals(Buffer.from(AASA_BYTES)),
    `dist/${AASA_PATH} does not have the expected bytes: ${JSON.stringify(AASA_BYTES)}.`,
  );
}

// 2. _headers sends the Associated Domains file as application/json. The file has no
// extension, so without this rule it has no Content-Type and Apple refuses it.
const headers = read(dist, "_headers");
if (check(headers !== null, "dist/_headers is missing.")) {
  const lines = headers.toString("utf8").split(/\r?\n/);
  const start = lines.findIndex((line) => line.trim() === `/${AASA_PATH}`);
  const rule = [];
  for (let i = start + 1; start >= 0 && i < lines.length && /^\s+\S/.test(lines[i]); i++) {
    rule.push(lines[i].trim());
  }
  check(
    rule.some((line) => /^content-type:\s*application\/json$/i.test(line)),
    `dist/_headers has no rule that sets "Content-Type: application/json" for /${AASA_PATH}.`,
  );
}

// 3. The sign-in callback page is a copy of the source, with no change by the build.
const callback = read(dist, CALLBACK_PATH);
if (check(callback !== null, `dist/${CALLBACK_PATH} is missing.`)) {
  const original = read(source, CALLBACK_PATH);
  check(
    original !== null && callback.equals(original),
    `dist/${CALLBACK_PATH} is not the same as public/${CALLBACK_PATH}.`,
  );
  check(
    callback.includes('<meta name="robots" content="noindex">'),
    `dist/${CALLBACK_PATH} has no noindex meta tag.`,
  );
}

// 4. The Sparkle appcast, when the source has one. The release workflow writes it.
const appcastSource = read(source, APPCAST_PATH);
if (appcastSource !== null) {
  const appcast = read(dist, APPCAST_PATH);
  check(
    appcast !== null && appcast.equals(appcastSource),
    `dist/${APPCAST_PATH} is missing or is not the same as public/${APPCAST_PATH}.`,
  );
}

// 5. The 404 page. wrangler.jsonc sets not_found_handling to "404-page".
check(read(dist, "404.html") !== null, "dist/404.html is missing.");

// The owner must set the store links in src/config.ts. Until then, the download page shows
// "Coming soon". This is a warning, not an error.
const config = readFileSync(new URL("src/config.ts", web), "utf8");
for (const name of ["appStoreUrl", "polarUrl"]) {
  if (new RegExp(`export const ${name}\\b[^=]*=\\s*null\\s*;`).test(config)) {
    console.warn(`Warning: ${name} in src/config.ts is null. The download page shows "Coming soon".`);
  }
}

if (errors.length > 0) {
  console.error(`The build in ${fileURLToPath(dist)} is not ready for a deploy:`);
  for (const error of errors) console.error(`- ${error}`);
  process.exit(1);
}

const appcastNote = appcastSource === null ? "" : ", the appcast";
console.log(
  `OK: dist has the Associated Domains file, its _headers rule, the sign-in callback page${appcastNote} and the 404 page.`,
);
