#!/usr/bin/env pwsh
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

Push-Location -Path "\\wsl$\Ubuntu\home\truman\dev\sila-showcase\SILA-presentation"
try {
    Write-Host "Running PowerShell smoke test (dry-run)..."
     & .\scripts\generate_epic_svgs.ps1 -Compress -Keep 1 -Render -DryRun
    $rc = $LASTEXITCODE
    if ($rc -ne 0) {
        Write-Error "generate_epic_svgs.ps1 returned exit code $rc"
        exit 1
    }
    Write-Host "Smoke PS: OK"
    Get-Content .\logs\last-run.log -Tail 100 | Write-Host
} catch {
    Write-Error "Smoke PS failed: $_"
    exit 2
} finally {
    Pop-Location
}

exit 0
