// node check.mjs — is the remote Firefox reachable and logged in to the app?
import { Driver } from './driver.mjs';
import { BASE_URL, TOKEN_KEY } from './config.mjs';

const d = new Driver();
await d.connect();
const at = await d.run('return location.href');
console.log('driver tab:', at);
if (at.startsWith(BASE_URL)) {
  console.log('logged in:', await d.run('return !!localStorage.getItem(arg)', TOKEN_KEY));
} else {
  console.log(`(tab is not on ${BASE_URL}; run capture.mjs, it checks login itself)`);
}
