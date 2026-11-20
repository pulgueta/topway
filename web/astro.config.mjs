// @ts-check
import { fileURLToPath } from "node:url";
import { defineConfig } from "astro/config";

// The privacy page renders PRIVACY.md from the root of the repository, so the file has one
// source. It is outside the project, so the dev server must be allowed to read it.
const projectRoot = fileURLToPath(new URL(".", import.meta.url));
const privacyPolicy = fileURLToPath(new URL("../PRIVACY.md", import.meta.url));

export default defineConfig({
  site: "https://topway.pulgueta.com",
  output: "static",
  // Workers Static Assets serves download.html at /download and redirects /download/ and
  // /download.html to /download. These two settings make the same URLs in Astro.
  trailingSlash: "never",
  build: {
    format: "file",
  },
  vite: {
    server: {
      fs: {
        allow: [projectRoot, privacyPolicy],
      },
    },
  },
});
