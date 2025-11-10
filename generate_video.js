// Canonical orchestration script for SILA-presentation
// - robust browser detection
// - loads presentation.config.json and/or frames/*.svg
// - injects SVG into a page and screenshots frames into output/frames
// - SHORT_RUN=1 mode to speed local tests
// - prints final ffmpeg command for stitching

import fs from 'node:fs';
import path from 'node:path';
import child_process from 'node:child_process';
import { fileURLToPath } from 'node:url';

async function findBrowserExecutable() {
  // Priority: env var, puppeteer (if installed), common system paths, which
  const envPath = process.env.CHROME_PATH || process.env.CHROMIUM_PATH;
  if (envPath && fs.existsSync(envPath)) return envPath;

  // Try to detect puppeteer if available and get its shipped executable
  try {
    const mod = await import('puppeteer').catch(() => null);
    const pp = mod && (mod.default || mod);
    if (pp) {
      let p = null;
      try {
        // puppeteer may expose executablePath() or .executablePath
        if (typeof pp.executablePath === 'function') p = pp.executablePath();
        else if (pp.executablePath) p = pp.executablePath;
      } catch (e) {
        p = null;
      }
      if (p && fs.existsSync(p)) return p;
    }
  } catch (e) {
    // ignore - puppeteer not installed
  }

  // Common linux paths
  const candidates = [
    '/usr/bin/chromium-browser',
    '/usr/bin/chromium',
    '/usr/bin/google-chrome-stable',
    '/usr/bin/google-chrome',
    '/snap/bin/chromium'
  ];
  for (const c of candidates) {
    if (fs.existsSync(c)) return c;
  }

  // fallback to which
  try {
    const whichOut = child_process.execSync('which chromium-browser || which chromium || which google-chrome-stable || which google-chrome', {encoding:'utf8'}).trim();
    if (whichOut && fs.existsSync(whichOut)) return whichOut;
  } catch (e) {
    // not found
  }

  return null;
}

async function ensureDir(dir) {
  if (!fs.existsSync(dir)) fs.mkdirSync(dir, {recursive:true});
}

function loadConfig(configPath) {
  if (!fs.existsSync(configPath)) return null;
  try {
    return JSON.parse(fs.readFileSync(configPath, 'utf8'));
  } catch (e) {
    console.error('Failed to parse', configPath, e.message);
    return null;
  }
}

function normalizeSlidesFromConfig(config) {
  if (!config) return [];
  if (Array.isArray(config.slides)) return config.slides.map((s, i) => ({id: s.id || i, src: s.src || null, duration: s.duration || 1}));
  return [];
}

async function main() {
  const projectRoot = path.resolve(path.dirname(fileURLToPath(import.meta.url)));
  
  // Get presentation name from command line or use 'default'
  const presentationName = process.argv[2] || 'default';
  
  // Setup directories
  const framesDir = path.join(projectRoot, 'frames', presentationName);
  const configsDir = path.join(projectRoot, 'configs');
  const audioDir = path.join(projectRoot, 'audio');
  const outputRoot = path.join(projectRoot, 'output', presentationName);
  const framesOutputDir = path.join(outputRoot, 'frames');
  
  // Ensure directories exist
  await Promise.all([
    ensureDir(framesDir),
    ensureDir(configsDir),
    ensureDir(audioDir),
    ensureDir(framesOutputDir)
  ]);

  const SHORT_RUN = process.env.SHORT_RUN === '1';

  // Try presentation-specific config first, fall back to default
  const configPath = path.join(configsDir, `${presentationName}.json`);
  const defaultConfigPath = path.join(projectRoot, 'presentation.config.json');
  let config = loadConfig(configPath);
  if (!config) {
    console.log(`⚠️ Config não encontrado em ${configPath}, usando padrão...`);
    config = loadConfig(defaultConfigPath);
  }
  
  if (!config) {
    console.error('❌ Nenhuma configuração encontrada!');
    console.error(`Crie ${configPath} ou ${defaultConfigPath}`);
    process.exit(1);
  }

  const slides = normalizeSlidesFromConfig(config);

  // If no config slides, fall back to reading frames/*.svg
  let svgFiles = [];
  if (slides.length === 0) {
    if (fs.existsSync(framesDir)) {
      svgFiles = fs.readdirSync(framesDir).filter(f => f.toLowerCase().endsWith('.svg')).map(f => ({id: f, src: path.join(framesDir, f), duration:1}));
    }
  } else {
    // if slides reference src paths, resolve them; otherwise try frames dir matching
    svgFiles = slides.map(s => {
      let src = s.src;
      if (src && !path.isAbsolute(src)) src = path.join(projectRoot, src);
      if (!src && fs.existsSync(framesDir)) {
        // try to pick a file in frames by index
        const cand = fs.readdirSync(framesDir).filter(f => f.toLowerCase().endsWith('.svg'))[0];
        src = cand ? path.join(framesDir, cand) : null;
      }
      return {id: s.id, src, duration: s.duration || 1};
    }).filter(s => s.src && fs.existsSync(s.src));
  }

  if (svgFiles.length === 0) {
    console.error('No SVG frames found. Looked in presentation.config.json and frames/');
    process.exit(2);
  }

  // shorten for quick test
  if (SHORT_RUN) svgFiles = svgFiles.slice(0, Math.min(3, svgFiles.length));

  const browserExe = await findBrowserExecutable();
  if (!browserExe) {
    console.error('\nNo Chromium/Chrome executable found. Set CHROME_PATH or install chromium-browser.');
    console.error('Suggested (WSL): sudo apt update && sudo apt install -y chromium-browser');
    process.exit(3);
  }

  // Try to use puppeteer or puppeteer-core; prefer puppeteer if available
  let puppeteer = null;
  try {
    const mod = await import('puppeteer').catch(() => null);
    puppeteer = mod && (mod.default || mod);
  } catch (e) { puppeteer = null; }
  if (!puppeteer) {
    try {
      const mod = await import('puppeteer-core').catch(() => null);
      puppeteer = mod && (mod.default || mod);
    } catch (e) { puppeteer = null; }
  }
  if (!puppeteer) {
    console.error('Please install puppeteer or puppeteer-core in this project (npm i puppeteer --save).');
    process.exit(4);
  }

  const launchOpts = {headless: true, args: ['--no-sandbox','--disable-setuid-sandbox'], executablePath: browserExe};

  console.log('Launching browser at', browserExe);
  const browser = await puppeteer.launch(launchOpts);
  const page = await browser.newPage();

  // default viewport — can be customized by presentation.config.json via config.viewport
  const defaultViewport = (config && config.viewport) || {width: 1920, height: 1080};
  await page.setViewport(defaultViewport);

  let idx = 1;
  for (const s of svgFiles) {
    const svgPath = s.src;
    const svgRaw = fs.readFileSync(svgPath, 'utf8');

    // Minimal HTML wrapper that inlines the SVG
    const html = `<!doctype html>
    <html>
      <head>
        <meta charset="utf-8" />
        <meta name="viewport" content="width=device-width, initial-scale=1" />
        <style>html,body{margin:0;padding:0;background:transparent;height:100%;} svg{display:block;width:100%;height:100%;}</style>
      </head>
      <body>
        ${svgRaw}
      </body>
    </html>`;

    await page.setContent(html, {waitUntil: 'networkidle0', timeout: 60000});
    // small pause for font loading, images, etc.
    await page.waitForTimeout(150);

    const outName = `frame-${String(idx).padStart(4,'0')}.png`;
    const outPath = path.join(framesOutputDir, outName);

    // Take screenshot of full page (the SVG fills the page)
    await page.screenshot({path: outPath, omitBackground: false});
    console.log(`Wrote ${outPath}`);
    idx++;

    if (SHORT_RUN) {
      // small early-exit delay between frames for quick validation
      await page.waitForTimeout(50);
    }
  }

  await browser.close();

  // Check if ffmpeg is available
  let ffmpegAvailable = false;
  try {
    child_process.execSync('ffmpeg -version', { stdio: 'ignore' });
    ffmpegAvailable = true;
  } catch (e) {}

  if (!ffmpegAvailable) {
    console.log('\n⚠️ ffmpeg não encontrado! Instale primeiro:');
    console.log('  sudo apt update && sudo apt install -y ffmpeg');
    process.exit(5);
  }

  // Generate video with ffmpeg
  const fps = (config && config.fps) || 30;
  const audioPath = config.audio ? path.join(audioDir, config.audio) : null;
  
  // Base ffmpeg command for video
  let ffmpegCmd = [
    'ffmpeg -y',
    `-r ${fps}`,
    `-i "${path.join(framesOutputDir, 'frame-%04d.png')}"`,
    '-c:v libx264',
    '-profile:v high',
    '-preset:v slow',
    '-crf 18',
    '-pix_fmt yuv420p'
  ];

  // Add audio if specified and exists
  if (audioPath && fs.existsSync(audioPath)) {
    ffmpegCmd.push(`-i "${audioPath}"`);
    ffmpegCmd.push('-c:a aac');
    ffmpegCmd.push('-b:a 128k');
    ffmpegCmd.push('-shortest');
  } else if (audioPath) {
    console.log(`⚠️ Áudio ${audioPath} não encontrado, gerando vídeo sem áudio...`);
  }

  // Output file
  // Ensure output is a valid object
  const output = (config && typeof config.output === 'object') ? config.output : { filename: 'video.mp4' };
  const outputVideo = path.join(outputRoot, output.filename);
  ffmpegCmd.push(`"${outputVideo}"`);

  // Execute ffmpeg
  console.log('\n🎥 Gerando vídeo final...');
  try {
    child_process.execSync(ffmpegCmd.join(' '), { stdio: 'inherit' });
    console.log(`\n✅ Vídeo gerado com sucesso: ${outputVideo}`);
  } catch (error) {
    console.error(`\n❌ Erro ao gerar vídeo: ${error.message}`);
    process.exit(6);
  }

  console.log('\n📊 Resumo:');
  console.log(`• Frames processados: ${idx - 1}`);
  console.log(`• FPS: ${fps}`);
  console.log(`• Resolução: ${defaultViewport.width}x${defaultViewport.height}`);
  if (audioPath && fs.existsSync(audioPath)) {
    console.log(`• Áudio: ${audioPath}`);
  }
  console.log(`• Saída: ${outputVideo}`);
  
  console.log('\n✨ Concluído!');
}

main().catch(err => { console.error(err); process.exit(99); });
