#!/bin/bash
set -e

PRESENTATION="$1"
MODE="$2"

echo "[BUILD] Instalando dependências..."
npm ci

if [ "$MODE" = "short" ]; then
  echo "[RUN] Executando SHORT_RUN para '$PRESENTATION'"
  SHORT_RUN=1 node generate_video.js "$PRESENTATION"
else
  echo "[RUN] Executando modo completo para '$PRESENTATION'"
  node generate_video.js "$PRESENTATION"
fi

echo "[DONE] Vídeo gerado em output/$PRESENTATION/video.mp4"
