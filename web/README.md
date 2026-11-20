# Topway website

This folder has the website at [topway.pulgueta.com](https://topway.pulgueta.com). It is a static [Astro](https://astro.build) site. Cloudflare Workers Static Assets serves it, with no Worker script.

The site has these pages and files:

| Address | Source | Use |
|---|---|---|
| `/` | `src/pages/index.astro` | What Topway does. |
| `/download` | `src/pages/download.astro` | The Mac App Store and the DMG. |
| `/privacy` | `src/pages/privacy.astro` | Shows `PRIVACY.md` from the root of the repository. Change the policy there, not here. |
| `/appcast.xml` | `public/appcast.xml` | The Sparkle feed of the direct build. The release workflow changes it. |
| `/.well-known/apple-app-site-association` | `public/.well-known/apple-app-site-association` | The Associated Domains file of the sign-in. |
| `/oauth/callback` | `public/oauth/callback.html` | The sign-in callback page. |
| Any other address | `src/pages/404.astro` | The 404 page. |

## Keep the sign-in files

The sign-in of Topway stops without these files. [AGENTS.md](../AGENTS.md#sign-in-callback) tells why.

- `public/.well-known/apple-app-site-association`: do not change it.
- `public/_headers`: it sends that file as `application/json`. The file has no extension, so without this rule it has no `Content-Type`.
- `public/oauth/callback.html`: Astro copies it with no change.

A deploy replaces all the files of the site. `npm run build` runs `scripts/check-dist.mjs` after the build. The check stops with an error when `dist/` does not have these files with the correct contents, or does not have `appcast.xml` or `404.html`.

## Set the store links

Put the Mac App Store URL and the Polar URL in `src/config.ts`. While a link is `null`, the download page shows **Coming soon** in place of its button, and the build shows a warning.

## Run the site on your Mac

You need Node.js 22.23.4 or later.

```sh
cd web
npm ci
npm run dev
```

Open the address that the command shows, usually `http://localhost:4321`.

## Build the site

```sh
npm run build
```

The site goes into `dist/`. The build fails if the check of `dist/` finds a problem.

## Preview the site as Cloudflare serves it

`npm run preview` uses the Astro server. It does not read `_headers` and does not make the redirects of Cloudflare. To see the real behavior, use Wrangler. It runs on your Mac and needs no sign-in:

```sh
npm run build
npx wrangler dev
```

Open `http://localhost:8787`. Then make sure that the sign-in files work:

```sh
curl -sI http://localhost:8787/.well-known/apple-app-site-association
curl -sI http://localhost:8787/oauth/callback/
```

The first command must show `200` and `content-type: application/json`. The second must show `307` and `location: /oauth/callback`.

## Deploy the site

Only the owner of the Cloudflare account deploys. Before the first deploy, do these steps:

1. In the Cloudflare dashboard, find the Worker that serves `topway.pulgueta.com` now.
2. Make sure that `name` in `wrangler.jsonc` is the name of that Worker. A different name makes a second Worker.
3. Make sure that `routes` in `wrangler.jsonc` agrees with the domain of that Worker. Wrangler applies the routes of the file.

Then build and deploy:

```sh
cd web
npm ci
npm run build
npx wrangler deploy
```

After each deploy, make sure that the sign-in files and the appcast work:

```sh
curl -sI https://topway.pulgueta.com/.well-known/apple-app-site-association
curl -sI https://topway.pulgueta.com/oauth/callback
curl -s https://topway.pulgueta.com/appcast.xml
```

## Settings of Cloudflare

`wrangler.jsonc` sets these items:

- `html_handling` is `auto-trailing-slash`, the default. `/download` serves `download.html`. `/download/` and `/download.html` redirect to `/download`. The sign-in callback depends on this behavior.
- `not_found_handling` is `404-page`. An unknown address gets the 404 page with the status 404.
- There is no `main`, so there is no Worker script. The static files give all the behavior.

## The appcast

`public/appcast.xml` starts with a valid channel that has no items, so Sparkle finds no update and gets no 404 error. `scripts/release-direct.sh` adds each release to this file. A test with `generate_appcast` 2.10.1 showed that it keeps this channel and adds the first item. [Release the direct build](../docs/direct-distribution.md) tells how.

## Privacy

The site loads no analytics, no third-party script and no font from another server. It uses the system font of the device. The pictures of the app are HTML with sample data, not screenshots of an account.

Astro and Wrangler can send usage data about the commands that you run. To stop it, run `npx astro telemetry disable` and `npx wrangler telemetry disable`.
