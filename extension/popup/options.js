const form = document.getElementById('settings-form');
const serverUrlInput = document.getElementById('serverUrl');
const tokenInput = document.getElementById('token');
const statusDiv = document.getElementById('status');

// Load saved settings
chrome.storage.sync.get(['serverUrl', 'token'], (result) => {
  if (result.serverUrl) {
    serverUrlInput.value = result.serverUrl;
  }
  if (result.token) {
    tokenInput.value = result.token;
  }
});

function showStatus(message, isError = false) {
  statusDiv.textContent = message;
  statusDiv.classList.remove('hidden', 'success', 'error');
  statusDiv.classList.add(isError ? 'error' : 'success');

  setTimeout(() => {
    statusDiv.classList.add('hidden');
  }, 3000);
}

async function validateToken(serverUrl, token) {
  try {
    const response = await fetch(`${serverUrl}/api/auth/me`, {
      headers: {
        'Authorization': `Bearer ${token}`
      }
    });
    return response.ok;
  } catch (error) {
    return false;
  }
}

form.addEventListener('submit', async (e) => {
  e.preventDefault();

  const serverUrl = serverUrlInput.value.trim().replace(/\/$/, '');
  const token = tokenInput.value.trim();

  // Validate token
  const isValid = await validateToken(serverUrl, token);

  if (!isValid) {
    showStatus('Invalid token or server URL. Please check your settings.', true);
    return;
  }

  // Save settings
  chrome.storage.sync.set({
    serverUrl,
    token
  }, () => {
    showStatus('Settings saved successfully!');
  });
});
