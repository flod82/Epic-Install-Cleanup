#requires -Version 5.1
<#[
.SYNOPSIS
    Finds and removes orphaned Epic Games Launcher installation records.

.DESCRIPTION
    Epic Games Launcher stores local installation manifests (.item) and
    Epic Online Services stores matching installation records (.egi).
    If a game was deleted or its old drive no longer exists, these records
    can make Epic continue to show the game as installed.

    The script:
      1. Checks that Epic Games Launcher is closed.
      2. Reads Epic .item manifests.
      3. Finds manifests whose InstallLocation no longer exists.
      4. Creates a timestamped backup of affected .item/.egi files.
      5. Removes the matching .item and .egi records.

    The Epic account/library is NOT modified and no game files are deleted.

.PARAMETER DryRun
    Only reports what would be removed. No files are changed.

.PARAMETER Force
    Skips the final confirmation prompt. A backup is still created unless
    -NoBackup is also specified.

.PARAMETER NoBackup
    Do not create a backup. Not recommended.

.EXAMPLE
    .\Cleanup-EpicOrphanedInstalls.ps1

.EXAMPLE
    .\Cleanup-EpicOrphanedInstalls.ps1 -DryRun

.EXAMPLE
    .\Cleanup-EpicOrphanedInstalls.ps1 -Force

.NOTES
    Designed for Windows PowerShell 5.1+ and PowerShell 7+.
    Run with a normal user account first. If Windows denies access, run
    PowerShell as Administrator.
#>

[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
param(
    [switch]$DryRun,
    [switch]$Force,
    [switch]$NoBackup
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$ProgramData = $env:ProgramData
$ManifestPath = Join-Path $ProgramData 'Epic\EpicGamesLauncher\Data\Manifests'
$EgiPath = Join-Path $ProgramData 'Epic\EpicOnlineServicesShared\InstallHelper\InstalledItems'
$BackupRoot = Join-Path ([Environment]::GetFolderPath('Desktop')) 'Epic-Orphaned-Backup'
$Timestamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$BackupPath = Join-Path $BackupRoot $Timestamp

function Write-Info([string]$Message) {
    Write-Host $Message -ForegroundColor Cyan
}

function Write-Ok([string]$Message) {
    Write-Host $Message -ForegroundColor Green
}

function Write-Warn([string]$Message) {
    Write-Host $Message -ForegroundColor Yellow
}

function Write-Err([string]$Message) {
    Write-Host $Message -ForegroundColor Red
}

function Test-EpicRunning {
    $processes = Get-Process -ErrorAction SilentlyContinue |
        Where-Object {
            $_.ProcessName -in @('EpicGamesLauncher', 'EpicWebHelper', 'EpicOnlineServices')
        }

    return @($processes).Count -gt 0
}

function Get-OrphanedManifests {
    if (-not (Test-Path -LiteralPath $ManifestPath)) {
        throw "Epic manifest folder was not found: $ManifestPath"
    }

    $orphans = @()

    foreach ($file in Get-ChildItem -LiteralPath $ManifestPath -Filter '*.item' -File) {
        try {
            $data = Get-Content -LiteralPath $file.FullName -Raw -Encoding UTF8 | ConvertFrom-Json
        }
        catch {
            Write-Warn "Could not read manifest: $($file.Name)"
            continue
        }

        $installLocation = $data.InstallLocation
        $displayName = $data.DisplayName

        if ([string]::IsNullOrWhiteSpace($installLocation)) {
            continue
        }

        if (-not (Test-Path -LiteralPath $installLocation)) {
            $id = $file.BaseName
            $egiFile = Join-Path $EgiPath "$id.egi"

            $orphans += [PSCustomObject]@{
                Name       = if ([string]::IsNullOrWhiteSpace($displayName)) { $id } else { $displayName }
                Path       = $installLocation
                Id         = $id
                Manifest   = $file.FullName
                Egi        = $egiFile
                EgiExists  = Test-Path -LiteralPath $egiFile
            }
        }
    }

    return $orphans
}

function New-Backup([object[]]$Items) {
    if ($NoBackup) {
        Write-Warn 'Backup disabled by -NoBackup.'
        return
    }

    $backupManifests = Join-Path $BackupPath 'Manifests'
    $backupEgi = Join-Path $BackupPath 'InstalledItems'

    New-Item -ItemType Directory -Path $backupManifests -Force | Out-Null
    New-Item -ItemType Directory -Path $backupEgi -Force | Out-Null

    foreach ($item in $Items) {
        if (Test-Path -LiteralPath $item.Manifest) {
            Copy-Item -LiteralPath $item.Manifest -Destination $backupManifests -Force
        }

        if (Test-Path -LiteralPath $item.Egi) {
            Copy-Item -LiteralPath $item.Egi -Destination $backupEgi -Force
        }
    }

    Write-Ok "Backup created: $BackupPath"
}

Write-Host ''
Write-Host '============================================================' -ForegroundColor Cyan
Write-Host '   Epic Games Launcher - Orphaned Installation Cleanup' -ForegroundColor Cyan
Write-Host '============================================================' -ForegroundColor Cyan
Write-Host ''

if (Test-EpicRunning) {
    Write-Err 'Epic Games Launcher or an Epic helper process is still running.'
    Write-Host 'Close Epic Games Launcher completely and run this script again.'
    exit 1
}

if (-not (Test-Path -LiteralPath $ManifestPath)) {
    Write-Err "Manifest folder not found: $ManifestPath"
    exit 1
}

Write-Info 'Scanning Epic installation manifests...'
$orphans = @(Get-OrphanedManifests)

if ($orphans.Count -eq 0) {
    Write-Ok 'No orphaned installations found.'
    exit 0
}

Write-Host ''
Write-Warn "Found $($orphans.Count) orphaned installation record(s):"
Write-Host ''
$orphans |
    Select-Object Name, Path, EgiExists |
    Format-Table -AutoSize

Write-Host ''
Write-Host 'The script will remove local installation records only.'
Write-Host 'It will NOT delete game files and will NOT modify your Epic account/library.'
Write-Host ''

if ($DryRun) {
    Write-Ok 'Dry run: no files were changed.'
    exit 0
}

if (-not $Force) {
    $answer = Read-Host 'Create backup and remove these records? [Y/N]'
    if ($answer -notmatch '^(Y|y|J|j)$') {
        Write-Warn 'Cancelled. No files were changed.'
        exit 0
    }
}

if (-not $NoBackup) {
    Write-Info 'Creating backup...'
    New-Backup -Items $orphans
}

Write-Info 'Removing orphaned records...'
$removed = 0

foreach ($item in $orphans) {
    if (Test-Path -LiteralPath $item.Manifest) {
        if ($PSCmdlet.ShouldProcess($item.Manifest, "Remove orphaned Epic manifest")) {
            Remove-Item -LiteralPath $item.Manifest -Force
            Write-Ok "Removed .item: $($item.Name)"
            $removed++
        }
    }

    if (Test-Path -LiteralPath $item.Egi) {
        if ($PSCmdlet.ShouldProcess($item.Egi, "Remove matching Epic Online Services record")) {
            Remove-Item -LiteralPath $item.Egi -Force
            Write-Ok "Removed .egi:  $($item.Id)"
        }
    }
}

Write-Host ''
Write-Host '============================================================' -ForegroundColor Green
Write-Host 'Cleanup completed.' -ForegroundColor Green
Write-Host '============================================================' -ForegroundColor Green
Write-Host "Installation records removed: $removed"
if (-not $NoBackup) {
    Write-Host "Backup: $BackupPath"
}
Write-Host ''
Write-Host 'Start Epic Games Launcher again and check your Library.'
