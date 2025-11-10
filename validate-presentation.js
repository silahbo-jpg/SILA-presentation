import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

// Get presentation name from command line
const presentationName = process.argv[2] || 'default';

// Setup paths
const projectRoot = path.resolve(path.dirname(fileURLToPath(import.meta.url)));
const configPath = path.join(projectRoot, 'configs', `${presentationName}.json`);
const defaultConfigPath = path.join(projectRoot, 'presentation.config.json');
const framesDir = path.join(projectRoot, 'frames', presentationName);
const audioDir = path.join(projectRoot, 'audio');
const outputRoot = path.join(projectRoot, 'output', presentationName);
const framesOutDir = path.join(outputRoot, 'frames');
const reportPath = path.join(outputRoot, 'diagnostics.md');

function validateConfig() {
  // Try presentation-specific config first
  if (fs.existsSync(configPath)) {
    try {
      const config = JSON.parse(fs.readFileSync(configPath, 'utf8'));
      const slides = Array.isArray(config.slides) ? config.slides.length : 0;
      const hasAudio = config.audio && fs.existsSync(path.join(audioDir, config.audio));
      return `✅ ${path.basename(configPath)} carregado. Slides: ${slides}, Áudio: ${hasAudio ? '✓' : '✗'}`;
    } catch (err) {
      return `❌ Erro ao ler ${path.basename(configPath)}: ${err.message}`;
    }
  }
  
  // Fall back to default config
  if (fs.existsSync(defaultConfigPath)) {
    try {
      const config = JSON.parse(fs.readFileSync(defaultConfigPath, 'utf8'));
      const slides = Array.isArray(config.slides) ? config.slides.length : 0;
      return `⚠️ Usando configuração padrão. Slides: ${slides}`;
    } catch (err) {
      return `❌ Erro ao ler configuração padrão: ${err.message}`;
    }
  }
  
  return '❌ Nenhuma configuração encontrada.';
}

function validateSVGs() {
  if (!fs.existsSync(framesDir)) return '❌ frames/ directory not found.';
  const files = fs.readdirSync(framesDir).filter(f => f.toLowerCase().endsWith('.svg'));
  if (files.length === 0) return '⚠️ No SVG files found in frames/.';
  const broken = files.filter(f => {
    const content = fs.readFileSync(path.join(framesDir, f), 'utf8');
    return !content.includes('<svg');
  });
  return `✅ SVGs found: ${files.length}. Broken files: ${broken.length}${broken.length ? ` → ${broken.join(', ')}` : ''}`;
}

function validateFramesOut() {
  if (!fs.existsSync(framesOutDir)) {
    fs.mkdirSync(framesOutDir, { recursive: true });
    return '✅ Diretório de frames criado.';
  }
  const files = fs.readdirSync(framesOutDir).filter(f => f.endsWith('.png'));
  if (files.length === 0) return '⚠️ Nenhum frame gerado ainda.';
  return `✅ ${files.length} frames encontrados em ${path.relative(projectRoot, framesOutDir)}`;
}

function generateReport() {
  const lines = [
    '# 📊 Diagnóstico da Apresentação',
    '',
    `**Apresentação:** ${presentationName}`,
    `**Gerado em:** ${new Date().toLocaleString()}`,
    '',
    '## 📝 Validação da Configuração',
    validateConfig(),
    '',
    '## 🎨 Integridade dos SVGs',
    validateSVGs(),
    '',
    '## 🖼️ Validação dos Frames',
    validateFramesOut(),
    '',
    '## 📂 Estrutura de Diretórios',
    '```',
    `frames/${presentationName}/`,
    fs.existsSync(framesDir) ? fs.readdirSync(framesDir).map(f => `  ${f}`).join('\n') : '  (vazio)',
    '',
    'audio/',
    fs.existsSync(audioDir) ? fs.readdirSync(audioDir).map(f => `  ${f}`).join('\n') : '  (vazio)',
    '',
    'output/',
    fs.existsSync(outputRoot) ? fs.readdirSync(outputRoot).map(f => `  ${f}`).join('\n') : '  (vazio)',
    '```'
  ];
  
  fs.mkdirSync(path.dirname(reportPath), { recursive: true });
  fs.writeFileSync(reportPath, lines.join('\n'), 'utf8');
  console.log(`✅ Relatório salvo em: ${path.relative(projectRoot, reportPath)}`);
}

generateReport();
