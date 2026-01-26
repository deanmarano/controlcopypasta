# ControlCopyPasta Browser Extension

Save recipes from any website to your ControlCopyPasta instance.

## Installation

### Chrome / Edge / Brave

1. Copy `manifest.chrome.json` to `manifest.json`
2. Open `chrome://extensions/` (or equivalent)
3. Enable "Developer mode"
4. Click "Load unpacked" and select the `extension` folder

### Firefox

1. Copy `manifest.firefox.json` to `manifest.json`
2. Open `about:debugging#/runtime/this-firefox`
3. Click "Load Temporary Add-on"
4. Select `manifest.json` from the extension folder

## Setup

1. Open the extension options (right-click extension icon > Options)
2. Enter your ControlCopyPasta server URL (e.g., `http://localhost:4000`)
3. Enter your JWT token (get this after logging in via the web app)
4. Save settings

## Usage

1. Navigate to any recipe page
2. Click the ControlCopyPasta extension icon
3. The extension will detect the recipe using JSON-LD data
4. Click "Save Recipe" to add it to your collection

## Icons

Replace the placeholder icons in `icons/` with your own:
- `icon16.png` (16x16)
- `icon32.png` (32x32)
- `icon48.png` (48x48)
- `icon128.png` (128x128)

You can convert `icon.svg` to PNG using any image editor or online converter.

## Development

The extension uses:
- Manifest V3 for Chrome (manifest.chrome.json)
- Manifest V2 for Firefox (manifest.firefox.json)

Both share the same popup, content script, and background script code.
