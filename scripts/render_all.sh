#!/usr/bin/env bash
# render_all.sh - Automatiza validação, renderização e exportação de vídeo
# Uso: ./scripts/render_all.sh <nome-apresentacao>
# Exemplo: ./scripts/render_all.sh mat-2023

set -e

# Verifica se recebeu o nome da apresentação
if [ -z "$1" ]; then
    echo "❌ Erro: Informe o nome da apresentação"
    echo "Uso: $0 <nome-apresentacao>"
    echo "Exemplo: $0 mat-2023"
    exit 1
fi

PRESENTATION_NAME="$1"
PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
CONFIG_FILE="$PROJECT_ROOT/configs/$PRESENTATION_NAME.json"
FRAMES_DIR="$PROJECT_ROOT/frames/$PRESENTATION_NAME"
OUTPUT_ROOT="$PROJECT_ROOT/output/$PRESENTATION_NAME"
FRAMES_OUTPUT="$OUTPUT_ROOT/frames"
VIDEO_OUTPUT="$OUTPUT_ROOT/video.mp4"

# Função para imprimir cabeçalho
print_header() {
    echo "
🎬 SILA Presentation Renderer
📂 Apresentação: $PRESENTATION_NAME
"
}

# Verifica estrutura de diretórios
check_structure() {
    echo "▶️ Verificando estrutura..."
    
    if [ ! -d "$FRAMES_DIR" ]; then
        echo "❌ Pasta de frames não encontrada: $FRAMES_DIR"
        exit 1
    fi
    
    if [ ! -f "$CONFIG_FILE" ]; then
        echo "❌ Arquivo de configuração não encontrado: $CONFIG_FILE"
        exit 1
    fi
    
    # Cria diretórios de saída
    mkdir -p "$FRAMES_OUTPUT"
    echo "✅ Estrutura verificada"
}

# Limpa arquivos anteriores
clean_output() {
    echo "▶️ Limpando saída anterior..."
    rm -rf "$FRAMES_OUTPUT"/*
    echo "✅ Limpeza concluída"
}

# Valida a apresentação
validate_presentation() {
    echo "▶️ Validando apresentação..."
    node "$PROJECT_ROOT/validate-presentation.js" "$PRESENTATION_NAME"
    echo "✅ Validação concluída"
}

# Gera os frames
generate_frames() {
    echo "▶️ Gerando frames..."
    node "$PROJECT_ROOT/generate_video.js" "$PRESENTATION_NAME"
    echo "✅ Frames gerados"
}

# Executa pipeline completo
main() {
    print_header
    check_structure
    clean_output
    validate_presentation
    generate_frames
    
    echo "
✨ Processo concluído!
📂 Saída em: $OUTPUT_ROOT
🎥 Vídeo: $VIDEO_OUTPUT

Use node generate_video.js $PRESENTATION_NAME para gerar novamente.
"
}

main