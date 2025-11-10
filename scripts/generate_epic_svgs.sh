#!/usr/bin/env bash
set -euo pipefail

# SILA Epic SVG Generator
# Generates and manages SVG frames for the SILA presentation system
# Usage: ./generate_epic_svgs.sh [--render] [--backup] [--compress] [--keep N] [--short-run]

# Colors and logging
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'
log() { echo -e "${GREEN}[SILA]${NC} $1" | tee -a "$LOG_FILE"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1" | tee -a "$LOG_FILE"; }
error() { echo -e "${RED}[ERROR]${NC} $1" >&2 | tee -a "$LOG_FILE"; exit 1; }

# Default configuration
PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TARGET_DIR="$PROJECT_ROOT/frames/epic"
DO_BACKUP=0
DO_RENDER=0
DO_COMPRESS=0
KEEP=0
SHORT_RUN=0
LOG_DIR="$PROJECT_ROOT/logs"
LOG_FILE="$LOG_DIR/last-run.log"
DO_DRYRUN=0

# Parse arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --render) DO_RENDER=1 ;;
    --backup) DO_BACKUP=1 ;;
  --compress) DO_COMPRESS=1 ;;
  --dry-run|--dryrun|-d) DO_DRYRUN=1 ;;
  --retries) shift; RETRIES=${1:-3} ;;
  --short-run) SHORT_RUN=1 ;;
    --keep)
      shift
      if [[ $# -eq 0 ]]; then
        error "--keep requires a numeric argument"
      fi
      if ! [[ $1 =~ ^[0-9]+$ ]]; then
        error "--keep argument must be a number"
      fi
      KEEP=$1
      ;;
    --keep=*) KEEP="${1#*=}" ;;
    *) error "Opção desconhecida: $1" ;;
  esac
  shift
done

# prepare logs
mkdir -p "$LOG_DIR"
echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] START generate_epic_svgs.sh args: $*" >> "$LOG_FILE"
if [[ $DO_DRYRUN -eq 1 ]]; then echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] DRY-RUN enabled" | tee -a "$LOG_FILE"; fi

# Debug trap: log failing command and line on error
trap 'echo "[ERROR-TRACE] at line $LINENO: $BASH_COMMAND" | tee -a "$LOG_FILE"' ERR

# Function to check dependencies
check_dependencies() {
  local missing=0
  for cmd in inkscape convert identify; do
    if ! command -v "$cmd" &> /dev/null; then
      warn "Comando '$cmd' não encontrado. Necessário para render: $cmd"
      missing=1
    fi
  done
  if [[ $missing -eq 1 && $DO_RENDER -eq 1 && $DO_DRYRUN -eq 0 ]]; then
    error "Dependências faltando para renderização. Instale inkscape/imagemagick ou remova --render."
  fi
}

# Function to create backup
create_backup() {
  if [[ $DO_BACKUP -ne 1 ]]; then
    return
  fi

  # Make timestamped subdir inside project backup root: backup/epic/<timestamp>/
  TIMESTAMP=$(date +%Y%m%d_%H%M%S)
  BACKUPS_ROOT="$PROJECT_ROOT/backup/epic"
  BACKUP_DIR="$BACKUPS_ROOT/$TIMESTAMP"

  # Find SVGs to back up
  shopt -s nullglob
  svgs=("$TARGET_DIR"/*.svg)
  shopt -u nullglob

  if [[ ${#svgs[@]} -eq 0 ]]; then
    warn "Nenhum SVG encontrado em $TARGET_DIR — nada para fazer backup."
    return
  fi

  log "Criando backup em $BACKUP_DIR"
  if [[ $DO_DRYRUN -eq 1 ]]; then
    log "(dry-run) Would create dir: $BACKUP_DIR"
  else
    mkdir -p "$BACKUP_DIR"
  fi
  for f in "${svgs[@]}"; do
    if [[ $DO_DRYRUN -eq 1 ]]; then
      log "(dry-run) Would copy $f -> $BACKUP_DIR/"
    else
      cp --preserve=timestamps "$f" "$BACKUP_DIR/" || error "Falha ao copiar $f para backup"
    fi
  done

  if [[ $DO_COMPRESS -eq 1 ]]; then
    archive="$BACKUP_DIR.tar.gz"
    log "Compactando backup em $archive"
    mkdir -p "$BACKUPS_ROOT"
    if [[ $DO_DRYRUN -eq 1 ]]; then
      log "(dry-run) Would tar -czf $archive -C $BACKUPS_ROOT $TIMESTAMP"
    else
      tar -czf "$archive" -C "$BACKUPS_ROOT" "$TIMESTAMP" || error "Falha ao compactar backup"
      log "Backup compactado: $archive"
    fi
  fi

  log "Backup concluído: $BACKUP_DIR"
}

# Apply retention policy (keep N backups)
apply_retention() {
  if [[ $KEEP -le 0 ]]; then
    return
  fi

  BACKUPS_ROOT="$PROJECT_ROOT/backup/epic"
  mkdir -p "$BACKUPS_ROOT"
  shopt -s nullglob
  mapfile -t items < <(ls -1 "$BACKUPS_ROOT" 2>/dev/null | sort -r)
  shopt -u nullglob

  total=${#items[@]}
  if [[ $total -le $KEEP ]]; then
    log "Nada a remover — total $total backups"
    return
  fi

  for ((i=KEEP;i<total;i++)); do
    item="${items[i]}"
    rm -rf "$BACKUPS_ROOT/$item"
    log "Removido backup: $item"
  done
#!/usr/bin/env bash
set -euo pipefail

# SILA Epic SVG Generator
# Generates and manages SVG frames for the SILA presentation system
# Usage: ./generate_epic_svgs.sh [--render] [--backup] [--compress] [--keep N] [--short-run]

# Colors and logging
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'
log() { echo -e "${GREEN}[SILA]${NC} $1" | tee -a "$LOG_FILE"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1" | tee -a "$LOG_FILE"; }
error() { echo -e "${RED}[ERROR]${NC} $1" >&2 | tee -a "$LOG_FILE"; exit 2; }

# Default configuration
PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TARGET_DIR="$PROJECT_ROOT/frames/epic"
DO_BACKUP=0
DO_RENDER=0
DO_COMPRESS=0
KEEP=0
SHORT_RUN=0
LOG_DIR="$PROJECT_ROOT/logs"
LOG_FILE="$LOG_DIR/last-run.log"
DO_DRYRUN=0
RETRIES=3

# Parse arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --render|-r) DO_RENDER=1 ;;
    --backup) DO_BACKUP=1 ;;
    --compress|-c) DO_COMPRESS=1 ;;
    --dry-run|--dryrun|-d) DO_DRYRUN=1 ;;
    --retries) shift; RETRIES=${1:-3} ;;
    --short-run) SHORT_RUN=1 ;;
    --keep)
      shift
      if [[ $# -eq 0 ]]; then
        error "--keep requires a numeric argument"
      fi
      if ! [[ $1 =~ ^[0-9]+$ ]]; then
        error "--keep argument must be a number"
      fi
      KEEP=$1
      ;;
    --keep=*) KEEP="${1#*=}" ;;
    -k) shift; KEEP=${1:-0} ;;
    *) error "Opção desconhecida: $1" ;;
  esac
  shift
done

# prepare logs
mkdir -p "$LOG_DIR"
echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] START generate_epic_svgs.sh args: $*" >> "$LOG_FILE"
if [[ $DO_DRYRUN -eq 1 ]]; then echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] DRY-RUN enabled" | tee -a "$LOG_FILE"; fi

# Debug trap: log failing command and line on error
trap 'echo "[ERROR-TRACE] at line $LINENO: $BASH_COMMAND" | tee -a "$LOG_FILE"' ERR

# Function to check dependencies
check_dependencies() {
  local missing=0
  for cmd in inkscape convert identify; do
    if ! command -v "$cmd" &> /dev/null; then
      warn "Comando '$cmd' não encontrado. Necessário para render: $cmd"
      missing=1
    fi
  done
  if [[ $missing -eq 1 && $DO_RENDER -eq 1 && $DO_DRYRUN -eq 0 ]]; then
    error "Dependências faltando para renderização. Instale inkscape/imagemagick ou remova --render."
  fi
}

# Function to create backup
create_backup() {
  if [[ $DO_BACKUP -ne 1 ]]; then
    return
  fi

  # Make timestamped subdir inside project backup root: backup/epic/<timestamp>/
  TIMESTAMP=$(date +%Y%m%d_%H%M%S)
  BACKUPS_ROOT="$PROJECT_ROOT/backup/epic"
  BACKUP_DIR="$BACKUPS_ROOT/$TIMESTAMP"

  # Find SVGs to back up
  shopt -s nullglob
  svgs=("$TARGET_DIR"/*.svg)
  shopt -u nullglob

  if [[ ${#svgs[@]} -eq 0 ]]; then
    warn "Nenhum SVG encontrado em $TARGET_DIR — nada para fazer backup."
    return
  fi

  log "Criando backup em $BACKUP_DIR"
  if [[ $DO_DRYRUN -eq 1 ]]; then
    log "(dry-run) Would create dir: $BACKUP_DIR"
  else
    mkdir -p "$BACKUP_DIR"
  fi
  for f in "${svgs[@]}"; do
    if [[ $DO_DRYRUN -eq 1 ]]; then
      log "(dry-run) Would copy $f -> $BACKUP_DIR/"
    else
      cp --preserve=timestamps "$f" "$BACKUP_DIR/" || error "Falha ao copiar $f para backup"
    fi
  done

  if [[ $DO_COMPRESS -eq 1 ]]; then
    archive="$BACKUP_DIR.tar.gz"
    log "Compactando backup em $archive"
    mkdir -p "$BACKUPS_ROOT"
    if [[ $DO_DRYRUN -eq 1 ]]; then
      log "(dry-run) Would tar -czf $archive -C $BACKUPS_ROOT $TIMESTAMP"
    else
      tar -czf "$archive" -C "$BACKUPS_ROOT" "$TIMESTAMP" || error "Falha ao compactar backup"
      log "Backup compactado: $archive"
    fi
  fi

  log "Backup concluído: $BACKUP_DIR"
}

# Apply retention policy (keep N backups)
apply_retention() {
  if [[ $KEEP -le 0 ]]; then
    return
  fi

  BACKUPS_ROOT="$PROJECT_ROOT/backup/epic"
  mkdir -p "$BACKUPS_ROOT"
  shopt -s nullglob
  mapfile -t items < <(ls -1 "$BACKUPS_ROOT" 2>/dev/null | sort -r)
  shopt -u nullglob

  total=${#items[@]}
  if [[ $total -le $KEEP ]]; then
    log "Nada a remover — total $total backups"
    return
  fi

  for ((i=KEEP;i<total;i++)); do
    item="${items[i]}"
    rm -rf "$BACKUPS_ROOT/$item"
    log "Removido backup: $item"
  done
}

# Function to validate SVG files
validate_svg() {
  local file="$1"
  if [[ ! -f "$file" ]]; then
    error "Arquivo SVG não encontrado: $file"
  fi
  
  # Check if file is valid SVG
  if ! grep -q "<svg" "$file"; then
    error "Arquivo inválido, não é um SVG: $file"
  fi
  
  # Additional SVG validation could be added here
}

# Function to process SVG files
process_svg() {
  local file="$1"
  local output_dir="$2"
  
  validate_svg "$file"
  
  # Process SVG using Inkscape
  if [[ $DO_RENDER -eq 1 ]]; then
    log "Processando $file"
    local name="$(basename "${file%.*}")"
    local out="$output_dir/${name}.png"
    if [[ $DO_DRYRUN -eq 1 ]]; then
      log "(dry-run) Would render $file -> $out"
      return
    fi

    local attempt=1
    while [[ $attempt -le $RETRIES ]]; do
      if inkscape --export-type=png "$file" --export-filename="$out"; then
        log "Render succeeded: $out"
        break
      else
        warn "Render failed for $file (attempt $attempt)"
        ((attempt++))
        sleep $((attempt))
      fi
    done
    if [[ $attempt -gt $RETRIES ]]; then
      error "Falha ao processar $file após $RETRIES tentativas"
    fi
  fi
}

# Main execution

main() {
  log "Iniciando gerador de SVGs SILA - Modo EPIC"

  # Create backup if requested (do before processing so we save original files)
  create_backup

  # Check dependencies only if rendering is requested
  if [[ $DO_RENDER -eq 1 ]]; then
    check_dependencies
    # If any required binary is missing, fail now
    for cmd in inkscape convert identify; do
      if ! command -v "$cmd" &> /dev/null; then
        error "Dependência faltando: $cmd. Instale-a ou remova --render."
      fi
    done
  fi

  # Ensure target directory exists
  mkdir -p "$TARGET_DIR"

  # Generate default SVG frames if none exist (or always overwrite)
  log "Gerando SVGs padrão em $TARGET_DIR"
  declare -A frames=(
    ["frame_01_angola_map.svg"]="ANGOLA"
    ["frame_02_circuits.svg"]="CIRCUITOS"
    ["frame_03_hud_overlays.svg"]="HUD"
    ["frame_04_focus_luanda.svg"]="LUANDA"
  )

  for name in "${!frames[@]}"; do
    cat > "$TARGET_DIR/$name" <<EOF
<svg xmlns="http://www.w3.org/2000/svg" width="1920" height="1080">
  <rect width="100%" height="100%" fill="#001b33"/>
  <text x="50%" y="50%" font-size="120" fill="#00FFC0" text-anchor="middle" dominant-baseline="middle">${frames[$name]}</text>
</svg>
EOF
    log "SVG criado: $name"
  done

  # Process all SVG files
  local count=0
  for svg in "$TARGET_DIR"/*.svg; do
    [[ -f "$svg" ]] || continue
    process_svg "$svg" "$TARGET_DIR"
    ((count++))

    # Break early if short run
    [[ $SHORT_RUN -eq 1 && $count -ge 1 ]] && break
  done

  log "Processamento concluído. Total de arquivos: $count"

  # Retention
  apply_retention
}

# Run main function
main "$@"

# Ensure successful exit code for callers (test harness / CI)
exit 0