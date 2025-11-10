import fs from 'node:fs';
import path from 'node:path';
import puppeteer from 'puppeteer';

// puppeteer_export.js
// Opens the local `index.html`, waits for it to load, advances the slides and takes screenshots
// Usage: node puppeteer_export.js

const outDir = path.resolve(process.cwd(), 'SILA-presentation', 'frames_out');
if (!fs.existsSync(outDir)) fs.mkdirSync(outDir, { recursive: true });

(async () => {
  const browser = await puppeteer.launch({ headless: true, args: ['--no-sandbox'] });
  const page = await browser.newPage();

  const indexPath = path.resolve(process.cwd(), 'SILA-presentation', 'index.html');
  const fileUrl = 'file://' + indexPath;
  console.log('Opening', fileUrl);
  await page.goto(fileUrl, { waitUntil: 'networkidle2' });

  // resize to Full HD
  await page.setViewport({ width: 1920, height: 1080 });

  // small helper to ensure GSAP animations finish
  await page.waitForTimeout(800);

  // number of slides to capture (read from DOM)
  const slideCount = await page.evaluate(() => document.querySelectorAll('.slide').length || 5);
  console.log('Detected slides:', slideCount);

  for (let i = 1; i <= slideCount; i++) {
    console.log('Show slide', i);
    // invoke the global function if present or set currentSlide and call showSlide
    await page.evaluate((n) => {
      if (typeof window.nextSlide === 'function') {
        // we want to navigate until the desired slide is visible
        window.currentSlide = n;
        if (typeof window.showSlide === 'function') window.showSlide(n);
      } else {
        // fallback: add .visible class
        document.querySelectorAll('.slide').forEach((s) => (s.style.opacity = 0));
        const sl = document.getElementById('slide' + n);
        if (sl) sl.style.opacity = 1;
      }
    }, i);

    await page.waitForTimeout(900); // wait for transitions

    const filename = path.join(outDir, `slide_${String(i).padStart(3, '0')}.png`);
    await page.screenshot({ path: filename, fullPage: false });
    console.log('Saved', filename);
  }

  await browser.close();
  console.log('\nAll frames exported to', outDir);
  console.log('Next step (local): run ffmpeg to assemble the mp4. Example:');
  console.log(`ffmpeg -framerate 30 -i ${path.join('frames_out','slide_%03d.png')} -c:v libx264 -pix_fmt yuv420p SILA_presentation.mp4`);
})();
