# SILA Presentation — Epic SVG + Video Automação

Repository: https://github.com/silahbo-jpg/SILA-presentation
Repository name: silahbo-jpg
Project name: SILA-presentation
Contact: silahbo@gmail.com


Este projeto automatiza a geração de SVGs cinematográficos para vídeos do SILA Showcase.

## 🚀 Funcionalidades

| Função | Bash | PowerShell |
|--------|------|------------|
| Gerar SVGs | ✅ | ✅ |
| Backup automático | ✅ | ✅ |
| Compressão (`--compress`) | ✅ (`tar.gz`) | ✅ (`zip`) |
| Retenção (`--keep N`) | ✅ | ✅ |
| Renderização (`--render`) | ✅ | ✅ |

---

## 🧠 Geração de SVGs

### Bash

```bash
./scripts/generate_epic_svgs.sh
```

### PowerShell

```powershell
./scripts/generate_epic_svgs.ps1
```

---

## 💾 Opções

| Flag         | O que faz                          |
| ------------ | ---------------------------------- |
| `--compress` | Compacta backup                    |
| `--keep N`   | Mantém apenas os últimos N backups |
| `--render`   | Renderiza o vídeo após gerar SVGs  |

Exemplo full power:

```bash
./scripts/generate_epic_svgs.sh --compress --keep 5 --render
```

---

## ✅ Teste Automatizado (CI/CD)

```bash
./scripts/tests/test_smoke.sh
```

---

## Estrutura

```
frames/epic/         -> SVGs gerados
backup/epic/         -> Backups com timestamp
scripts/             -> Automação
scripts/tests/       -> Testes automatizados
```

---

Feito com 🚀 e 🇦🇴 Angola First.
SILA-presentation — Automação e assets

Conteúdo criado:
- index.html — apresentação interativa
- video_prompt.json — prompt para gerar vídeo em Runway/Pika
- frames/*.svg — 4 frames de referência (Angola, circuitos, HUD, foco em Luanda)
- generate_video.js — script template para enviar `video_prompt.json` a uma API (ex: Runway)
- puppeteer_export.js — (será criado) script para abrir `index.html`, avançar slides e capturar screenshots
- package.json — scripts utilitários

Como usar (rápido):

1) Instalar dependências (Node.js >=18 recomendado). No Powershell (na raiz `SILA-presentation`):

```powershell
cd SILA-presentation
npm install
```

2) Gerar vídeo via API (exemplo Runway):
- Exporte sua API key como variável de ambiente `RUNWAY_API_KEY`.
- Opcionalmente ajuste `RUNWAY_API_URL` se o provider usar outra rota.

```powershell
$env:RUNWAY_API_KEY = "YOUR_KEY_HERE"
npm run generate-video
```

O script `generate_video.js` é um template: providers podem exigir autenticação diferente ou endpoints distintos. O script salva a resposta do job em `video_job_response.json`.

3) Exportar slides como frames (requer `puppeteer` e `ffmpeg`):

```powershell
npm run export-frames
# depois usar ffmpeg para montar o mp4, exemplo:
ffmpeg -framerate 30 -i frames_out/slide_%03d.png -c:v libx264 -pix_fmt yuv420p out.mp4
```

Se precisares, eu adapto `generate_video.js` para um provider específico (Runway, Pika, Kaiber) e adiciono polling automático para baixar o vídeo quando pronto.
