#!/bin/bash
# ==========================================
#  SILA-Presentation - Generate Audio (ElevenLabs)
# ==========================================

AUDIO_DIR="./audio"
AUDIO_FILE="narration.mp3"
TEXT_FILE="./scripts/narration.txt"

# Lê a chave de API do environment
if [ -z "$ELEVENLABS_API_KEY" ]; then
  echo "❌ ELEVENLABS_API_KEY não definida!"
  echo "Exporta assim antes de executar:"
  echo "export ELEVENLABS_API_KEY=xxxxxxxxxxxxxxxxxxxx"
  exit 1
fi

mkdir -p "$AUDIO_DIR"

echo "🎤 Gerando narração com voz feminina cinematográfica (ElevenLabs)..."

curl -X POST "https://api.elevenlabs.io/v1/text-to-speech/pNInz6obpgDQGcFmaJgB" \
  -H "Content-Type: application/json" \
  -H "xi-api-key: $ELEVENLABS_API_KEY" \
  -d "{
        \"text\": \"$(cat $TEXT_FILE)\",
        \"voice_settings\": { \"stability\": 0.35, \"similarity_boost\": 0.92, \"style\": 73 }
      }" \
  --output "$AUDIO_DIR/$AUDIO_FILE"

echo "✅ Áudio salvo em: $AUDIO_DIR/$AUDIO_FILE"