[CmdletBinding()]
param(
    [Parameter(Mandatory=$false)][Alias('c')][switch]$Compress,
    [Parameter(Mandatory=$false)][Alias('k')][int]$Keep = 0,
    [Parameter(Mandatory=$false)][Alias('r')][switch]$Render,
    [Parameter(Mandatory=$false)][Alias('d')][switch]$DryRun,
    [Parameter(Mandatory=$false)][Alias('t')][int]$Retries = 3
)

$ErrorActionPreference = 'Stop'

# Basic paths and logging
$ProjectRoot = Split-Path -Parent $PSScriptROOT
$epicDir     = Join-Path $ProjectRoot 'frames\epic'
$backupRoot  = Join-Path $ProjectRoot 'backup\epic'
$timestamp   = Get-Date -Format 'yyyyMMdd_HHmmss'
$backupDir   = Join-Path $backupRoot $timestamp
$logDir      = Join-Path $ProjectRoot 'logs'
$logFile     = Join-Path $logDir 'last-run.log'

function Write-Log([string]$Message) {
    Write-Host "[✔] $Message" -ForegroundColor Green
    Add-Content -Path $logFile -Value "[$(Get-Date -Format o)] $Message"
}
function Write-Warn([string]$Message) {
    Write-Host "[!] $Message" -ForegroundColor Yellow
    Add-Content -Path $logFile -Value "[$(Get-Date -Format o)] WARN: $Message"
}
function Write-ErrorMsg([string]$Message) {
    Write-Host "[✖] $Message" -ForegroundColor Red
    Add-Content -Path $logFile -Value "[$(Get-Date -Format o)] ERROR: $Message"
    exit 1
}
function Write-Info([string]$Message) {
    Write-Host "[➤] $Message" -ForegroundColor Cyan
    Add-Content -Path $logFile -Value "[$(Get-Date -Format o)] $Message"
}

if (-not (Test-Path -Path (Join-Path $ProjectRoot 'scripts'))) {
    Write-ErrorMsg "Executa este script dentro de SILA-presentation/"
}

# Ensure dirs and log exist
New-Item -ItemType Directory -Force -Path $epicDir  | Out-Null
New-Item -ItemType Directory -Force -Path $backupRoot | Out-Null
New-Item -ItemType Directory -Force -Path $logDir    | Out-Null
"[$(Get-Date -Format o)] START generate_epic_svgs.ps1 args: Compress=$Compress Keep=$Keep Render=$Render DryRun=$DryRun Retries=$Retries" | Add-Content -Path $logFile

# Backup existing SVGs (move to backupRoot/timestamp)
$existingSvgs = Get-ChildItem -Path $epicDir -Filter '*.svg' -File -ErrorAction SilentlyContinue
if ($existingSvgs -and $existingSvgs.Count -gt 0) {
    Write-Info "Backup detectado — movendo ficheiros para $backupDir"
    if ($DryRun) {
        Write-Log "(dry-run) Would create $backupDir and move $($existingSvgs.Count) files"
    } else {
        New-Item -ItemType Directory -Force -Path $backupDir | Out-Null
        foreach ($s in $existingSvgs) { Move-Item -Path $s.FullName -Destination $backupDir }
        Write-Log "Backup criado: $backupDir"
    }
} else {
    Write-Log "Nenhum SVG existente encontrado."
}

# Generate SVGs
Write-Info "Gerando SVGs…"

$frames = @{
    'frame_01_angola_map.svg'   = 'ANGOLA'
    'frame_02_circuits.svg'     = 'CIRCUITOS'
    'frame_03_hud_overlays.svg' = 'HUD'
    'frame_04_focus_luanda.svg' = 'LUANDA'
}

foreach ($frame in $frames.Keys) {
    $content = @"
<svg xmlns='http://www.w3.org/2000/svg' width='1920' height='1080'>
  <rect width='100%' height='100%' fill='#001b33'/>
  <text x='50%' y='50%' font-size='120' fill='#00FFC0' text-anchor='middle' dominant-baseline='middle'>$($frames[$frame])</text>
</svg>
"@
    $path = Join-Path $epicDir $frame
    $content | Out-File -FilePath $path -Encoding utf8 -Force
    Write-Log "SVG criado: $frame"
}

# Compress backup if requested
if ($Compress) {
    Write-Info "Compactando backup…"
    $archive = "$backupDir.zip"
    if ($DryRun) {
        Write-Log "(dry-run) Would create archive $archive"
    } else {
        if (-not (Test-Path -Path $backupDir)) { Write-ErrorMsg "Diretório de backup não existe: $backupDir" }
        Compress-Archive -Path (Join-Path $backupDir '*') -DestinationPath $archive -Force
        Remove-Item -Path $backupDir -Recurse -Force
        Write-Log "Backup compactado: $archive"
    }
}

# Retention — keep last N backups
if ($Keep -gt 0) {
    Write-Info "Aplicando política de retenção (keep $Keep backups)"
    $backups = Get-ChildItem -Path $backupRoot | Sort-Object LastWriteTime -Descending
    $total = $backups.Count
    if ($total -gt $Keep) {
        $remove = $backups[$Keep..($total - 1)]
        foreach ($r in $remove) { Remove-Item -Path $r.FullName -Recurse -Force; Write-Log "Removido backup: $($r.Name)" }
    } else { Write-Log "Nada a remover — total $total backups" }
}

function Test-Dependencies {
    $missing = $false
    foreach ($cmd in @('inkscape','magick')) {
        if (-not (Get-Command $cmd -ErrorAction SilentlyContinue)) { Write-Warn "Command not found: $cmd"; $missing = $true }
    }
    if ($missing -and $Render -and -not $DryRun) { Write-ErrorMsg "Dependências faltando para render. Instale inkscape/magick." }
}

function Invoke-RenderWithRetry {
    param([int]$attempts)
    $renderScript = Join-Path $ProjectRoot 'scripts\\render_all.ps1'
    if (-not (Test-Path -Path $renderScript)) { Write-Warn "Render script não encontrado: $renderScript"; return }
    $i = 1
    while ($i -le $attempts) {
        Write-Info "Running render attempt $i/$attempts"
        if ($DryRun) { Write-Log "(dry-run) Would invoke $renderScript epic"; return }
        try {
            & $renderScript 'epic'
            Write-Log "Render script finished successfully"
            return
        } catch {
            Write-Warn "Render attempt $i failed: $_"
            Start-Sleep -Seconds ($i)
        }
        $i++
    }
    Write-ErrorMsg "Render failed after $attempts attempts"
}

if ($Render) {
    Write-Info "Iniciando renderização 🎬"
    Test-Dependencies
    Invoke-RenderWithRetry -attempts $Retries
}

Write-Log "🏁 Processo concluído com sucesso."
