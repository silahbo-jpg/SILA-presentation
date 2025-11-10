#!/usr/bin/env node
import fs from 'node:fs';
import path from 'node:path';
import child_process from 'node:child_process';
import { fileURLToPath } from 'node:url';

function which(cmd) {
  try {
    return child_process.execSync(`which ${cmd}`, { encoding: 'utf8' }).trim();
  } catch (e) {
    return null;
  }
}

(async function main(){
  const nodeVersion = process.versions.node;
  console.log('Node version:', nodeVersion);

  const projectRoot = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
  console.log('Project root:', projectRoot);

  // check if node_modules exists
  const nodeModules = path.join(projectRoot, 'node_modules');
  console.log('node_modules exists:', fs.existsSync(nodeModules));

  // check puppeteer availability via dynamic import
  let puppeteerAvailable = false;
  try {
    const m = await import('puppeteer').catch(() => null);
    if (m) puppeteerAvailable = true;
  } catch (e) { }
  try {
    if (!puppeteerAvailable) {
      const m2 = await import('puppeteer-core').catch(() => null);
      if (m2) puppeteerAvailable = true;
    }
  } catch (e) { }
  console.log('puppeteer/puppeteer-core available:', puppeteerAvailable);

  // check chrome/chromium
  const candidates = ['google-chrome-stable', 'google-chrome', 'chromium-browser', 'chromium'];
  let found = null;
  for (const c of candidates) {
    const w = which(c);
    if (w) { found = w; break; }
  }
  console.log('Detected system Chrome/Chromium:', found || 'none');

  console.log('\nRecommended commands to fix common issues:');
  if (!fs.existsSync(nodeModules)) {
    console.log('  npm install  # install dependencies from package.json');
  }
  if (!puppeteerAvailable) {
    console.log('  npm install puppeteer --save  # or puppeteer-core if you prefer');
  }
  if (!found) {
    console.log("  sudo apt update && sudo apt install -y chromium-browser  # on WSL/Ubuntu to install Chromium\n  or set CHROME_PATH/CHROMIUM_PATH to a browser binary path");
  }
  console.log('\nAfter installing dependencies and browser, run:');
  console.log('  SHORT_RUN=1 node generate_video.js');
})();
