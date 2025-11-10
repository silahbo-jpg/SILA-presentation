# SILA Narration Generator

Script para geração de áudio narrativo via ElevenLabs.

## 🎯 Features

- Voz feminina cinematográfica otimizada
- Ritmo e pausas naturais
- Qualidade profissional para vídeos institucionais
- Fácil integração com o pipeline de vídeo

## 🔧 Configuração

1. Obtenha sua chave de API no [ElevenLabs](https://elevenlabs.io)
2. Configure a chave:
   ```bash
   export ELEVENLABS_API_KEY="sua-chave-aqui"
   ```

## 📝 Personalização

Para ajustar o texto da narração, edite:
`scripts/narration.txt`

## 🚀 Uso

Via terminal:
```bash
./scripts/generate_audio_elevenlabs.sh
```

Ou pelo VS Code:
1. Abra a paleta de comandos (Ctrl+Shift+P)
2. Digite: "Tasks: Run Build Task"
3. Selecione "🎤 SILA: Gerar Narração"

## ⚙️ Parâmetros de Voz

- Voice ID: pNInz6obpgDQGcFmaJgB (voz feminina cinematográfica)
- Stability: 0.35 (natural)
- Similarity Boost: 0.92 (consistente)
- Style: 73 (institucional/épico)

## 🎬 Integração com Vídeo

O áudio gerado é automaticamente usado pelo `generate_video.js` 
para criar o vídeo final com narração sincronizada.