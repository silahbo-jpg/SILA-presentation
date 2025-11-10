#!/usr/bin/env bash
set -euo pipefail

echo "🔍 Smoke Test — SVG Pipeline"
echo "-----------------------------"

./scripts/generate_epic_svgs.sh --compress --keep 3 --backup || true

mkdir -p "tmp_test"
cp frames/epic/*.svg tmp_test/ || true

[ -f tmp_test/frame_01_angola_map.svg ] || { echo "Missing frame_01"; exit 1; }

echo "✅ SVGs gerados"

if ls backup/epic/*.tar.gz 1> /dev/null 2>&1; then
    echo "✅ Compressão OK"
else
    echo "❌ Compressão falhou"
    exit 1
fi

count=$(ls -1 backup/epic 2>/dev/null | wc -l || true)
echo "🔢 Backups existentes: $count"

echo "✅ Smoke Test finalizado com sucesso"
