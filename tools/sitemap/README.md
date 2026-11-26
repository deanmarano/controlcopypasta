# App map

A Figma-style canvas of every page in the app: one frame per route, desktop and
mobile, grouped by area, with the in-page links between them. It exists so design
and product decisions can be made looking at the whole surface at once.

```bash
tools/sitemap/run            # capture everything, then build
open tools/sitemap/out/sitemap.html
```

`out/` is ignored by git: the screenshots are of a real account.

## What a run does

1. **Discovers routes** from `frontend/src/routes/**/+page.svelte`. A new page
   appears on the map with no config change.
2. **Screenshots each route** at 1440px and 390px, full page, through the
   long-running remote Firefox (via `remote-firefox-driver`). Dynamic routes such
   as `/recipes/[id]` are opened using the first matching link found on their
   parent page, so the examples are real data.
3. **Saves each page** with the Save Page WE extension into `out/pages/`
   (self-contained HTML you can open and inspect offline).
4. **Builds `out/sitemap.html`**: one file, screenshots inlined.

Logged-out pages (`/`, `/login`, `/auth/verify`) are captured by setting the auth
token aside in `localStorage` for that pass and putting it back afterwards. If a
run is killed mid-pass, the next run restores it.

## Options

```bash
node capture.mjs --only=/recipes        # recapture one area, keep the rest
node capture.mjs --include=admin,design # also capture /admin and /mockups, /styleguide
node capture.mjs --no-pages             # screenshots only
node build.mjs                          # rebuild the HTML without recapturing
node build.mjs --standalone             # out/sitemap-standalone.html: one file with no saved-page links, for hosting
```

`config.mjs` holds the sections, viewports, which routes are logged-out, the
height cap for very long pages, and `PARAMS` for pinning a specific example id.

## Requirements

- The remote Firefox is connected to the driver and **logged in** to the app
  (sign in once over noVNC; the session lives in the Firefox profile).
- Driver key in `RFD_API_KEY` or `RFD_API_KEY_FILE`; otherwise it is read with
  `dokku config:get remote-firefox-driver API_KEY`.
- ImageMagick (`magick`) for stitching, and `docker` access to the
  `remote-firefox.web.1` container for the Save Page WE hotkey.

Put machine-specific values in an untracked `tools/sitemap/.env` (copy `.env.example`).

| Variable | Default |
|---|---|
| `SITEMAP_BASE_URL` | `https://controlcopypasta.com` |
| `SITEMAP_MAX_HEIGHT` | `7000` |
| `RFD_URL` | `http://localhost:3000` |
| `RFD_DOWNLOADS` | none: host path of the remote Firefox's Downloads folder, needed for saved pages |
| `RFD_BROWSER_CONTAINER` | `remote-firefox.web.1` |

## How the awkward parts work

- **Full-page and mobile shots.** The driver can only capture the visible
  viewport of a 1440px window. So the tab is parked on a blank same-origin
  document holding an iframe sized to the target viewport; the route loads in the
  iframe, the iframe is stretched to the page's full height, and the outer page
  is scrolled and captured in tiles that ImageMagick stitches together. Media
  queries see the iframe's width, so the 390px frame is the real mobile layout.
- **Save Page WE.** It only reacts to its toolbar button or `Alt+A`, and no
  extension API can press either. `vnc-key.pl` sends `Alt+A` to the browser's X
  display over the container's internal VNC socket; the script then picks the new
  file up from the Downloads folder.
- **The driver controls one tab.** A run takes over the driver's active tab and
  hands it back at the end, so don't run it while something else is using the
  same browser session.

## Limits

- One state per route: no open modals, menus, empty states or error states.
- Links are read from `<a href>` only. A page reached solely by a button shows as
  "no links in".
- A route whose parent page has no link to an example (an empty inbox, say) is
  drawn as a placeholder.
