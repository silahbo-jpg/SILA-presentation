#!/usr/bin/env pwsh

[CmdletBinding()]
param(
    [Alias('c')][switch]$Compress,
    [Alias('k')][int]$Keep = 0,
    [Alias('r')][switch]$Render,
    [switch]$DryRun
)

$ErrorActionPreference = 'Stop'

# UNC-safe project path (literal)
$ProjectPath = '\wsl$\Ubuntu\home\truman\dev\sila-showcase\SILA-presentation'
$FrameDir = Join-Path $ProjectPath 'frames\epic'
$BackupDir = Join-Path $ProjectPath 'backups'
$LogDir = Join-Path $ProjectPath 'logs'
$LogFile = Join-Path $LogDir 'last-run.log'

if (-not (Test-Path $LogDir)) { New-Item -ItemType Directory -Force -Path $LogDir | Out-Null }

function Log([string]$msg) {
    $line = "$(Get-Date -Format o) - $msg"
    Add-Content -Path $LogFile -Value $line
    Write-Host $msg
}

Log '=== RUN STARTED ==='
Log "Compress=$Compress Keep=$Keep Render=$Render DryRun=$DryRun"

if (-not (Test-Path $FrameDir)) { New-Item -ItemType Directory -Force -Path $FrameDir | Out-Null }

function Generate-SVG {
    param([string]$file, [string]$content)
    $dest = Join-Path $FrameDir $file
    if ($DryRun) { Log "[DRYRUN] Write -> $dest"; return }
    $content | Out-File -FilePath $dest -Encoding UTF8 -Force
    Log "[OK] Generated $file"
}

Generate-SVG 'frame_01_angola_map.svg' @"
<svg width='1920' height='1080' xmlns='http://www.w3.org/2000/svg'>
  <rect width='100%' height='100%' fill='#cce6ff'/>
  <text x='50%' y='50%' font-size='120' fill='#003366' text-anchor='middle' dominant-baseline='middle'>ANGOLA</text>
</svg>
"@

Generate-SVG 'frame_02_circuits.svg' @"
<svg width='1920' height='1080' xmlns='http://www.w3.org/2000/svg'>
  <rect width='100%' height='100%' fill='#0a0a0a'/>
  <circle cx='960' cy='540' r='5' fill='#00ffff'/>
</svg>
"@

Generate-SVG 'frame_03_hud_overlays.svg' @"
<svg width='1920' height='1080' xmlns='http://www.w3.org/2000/svg'>
  <rect width='100%' height='100%' fill='#001f3f'/>
  <circle cx='960' cy='540' r='300' stroke='#00ffcc' stroke-width='4' fill='none'/>
</svg>
"@

Generate-SVG 'frame_04_focus_luanda.svg' @"
<svg width='1920' height='1080' xmlns='http://www.w3.org/2000/svg'>
  <rect width='100%' height='100%' fill='#003366'/>
  <text x='960' y='540' font-size='100' fill='#ff3333' text-anchor='middle' dominant-baseline='middle'>LUANDA</text>
</svg>
"@

# Backup + compress + retention
if ($Compress) {
    if (-not (Test-Path $BackupDir)) { New-Item -ItemType Directory -Force -Path $BackupDir | Out-Null }
    $timestamp = Get-Date -Format 'yyyyMMdd_HHmmss'
    $backupFile = Join-Path $BackupDir "epic_$timestamp.zip"

    if (-not $DryRun) {
        Compress-Archive -Path (Join-Path $FrameDir '*.svg') -DestinationPath $backupFile -Force
    }
    Log "[OK] Backup saved: $backupFile"

    if ($Keep -gt 0) {
    $files = @(Get-ChildItem -Path $BackupDir -Filter '*.zip' | Sort-Object CreationTime -Descending)
        if ($files.Count -gt $Keep) {
            $filesToDelete = $files[$Keep..($files.Count - 1)]
            foreach ($f in $filesToDelete) {
                if (-not $DryRun) { Remove-Item $f.FullName -Force }
                Log "[RETENTION] Removed $($f.Name)"
            }
        }
    }
}

# Render via WSL
if ($Render) {
    Log '[RENDER] Invoking render_all.sh...'
    if (-not $DryRun) {
        wsl bash -lc "cd /home/truman/dev/sila-showcase/SILA-presentation && SHORT_RUN=1 ./scripts/render_all.sh epic"
    }
}

Log '=== RUN COMPLETE ==='
exit 0