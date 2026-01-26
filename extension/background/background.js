// Background service worker for ControlCopyPasta extension

// Handle extension installation
chrome.runtime.onInstalled.addListener((details) => {
  if (details.reason === 'install') {
    // Set default server URL
    chrome.storage.sync.set({
      serverUrl: 'http://localhost:4000'
    });
  }
});

// Handle messages from popup or content scripts
chrome.runtime.onMessage.addListener((request, sender, sendResponse) => {
  if (request.action === 'getSettings') {
    chrome.storage.sync.get(['serverUrl', 'token'], (result) => {
      sendResponse(result);
    });
    return true; // Keep channel open for async response
  }

  if (request.action === 'saveSettings') {
    chrome.storage.sync.set(request.settings, () => {
      sendResponse({ success: true });
    });
    return true;
  }
});
