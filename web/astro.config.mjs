// @ts-check
import { defineConfig } from "astro/config";

export default defineConfig({
  site: "https://topway.pulgueta.com",
  output: "static",
  // Workers Static Assets serves download.html at /download and redirects /download/ and
  // /download.html to /download. These two settings make the same URLs in Astro.
  trailingSlash: "never",
  build: {
    format: "file",
  },
});
