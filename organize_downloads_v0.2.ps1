<#
.SYNOPSIS
  Organize Downloads v0.2 - sort, hash duplicates, auto-clean old installers, logging.
  Self-contained: all settings are in this script (edit the SETTINGS block below).
.PARAMETER SourcePath
  Override source folder (optional).
.PARAMETER TargetPath
  Override target folder (optional).
.PARAMETER DryRun
  Show what would be done, no moves.
.PARAMETER SkipDuplicates
  Do not find duplicates by hash.
.PARAMETER SkipAutoClean
  Do not move old installers to _Quarantine.
#>

[CmdletBinding()]
param(
    [string] $SourcePath = "",
    [string] $TargetPath = "",
    [switch] $DryRun,
    [switch] $SkipDuplicates,
    [switch] $SkipAutoClean
)

# UTF-8
$OutputEncoding = [System.Text.Encoding]::UTF8
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# ========== SETTINGS (edit here, no external files) ==========
$script:DefaultSource   = Join-Path $env:USERPROFILE "Downloads"
$script:DefaultTarget   = "E:\Temponary\.Downloads"
$script:OldInstallerDays = 30
$script:ChatExportPattern = "google|gemini|gpt|chat"
$script:Folders = @{
    "Installers"   = @(".exe", ".msi")
    "Images"       = @(".png", ".jpg", ".jpeg", ".gif", ".webp", ".bmp", ".ico")
    "Videos"       = @(".mp4", ".mkv", ".avi", ".mov", ".wmv", ".webm")
    "Audio"        = @(".mp3", ".wav", ".flac", ".m4a", ".ogg")
    "Archives"     = @(".zip", ".7z", ".rar", ".tar", ".gz")
    "Documents"    = @(".txt", ".xlsx", ".xls", ".pdf", ".docx", ".doc", ".md")
    "chat_export"  = @()
    "_Quarantine"  = @()
    "_Duplicates"  = @()
    "Other"        = @()
}
# ========== END SETTINGS ==========

# Params override script settings
if ($SourcePath) { $script:DefaultSource = $SourcePath }
if ($TargetPath) { $script:DefaultTarget = $TargetPath }

$script:SourceBase = $script:DefaultSource
$script:TargetBase = $script:DefaultTarget
$script:LogPath = Join-Path $script:TargetBase "organize.log"
$script:DryRun = $DryRun.IsPresent
$script:SkipDuplicates = $SkipDuplicates.IsPresent
$script:SkipAutoClean = $SkipAutoClean.IsPresent

function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $line = "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] [$Level] $Message"
    try {
        $dir = Split-Path $script:LogPath -Parent
        if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
        Add-Content -LiteralPath $script:LogPath -Value $line -Encoding UTF8 -ErrorAction SilentlyContinue
    } catch { }
    if ($Level -eq "ERROR" -or $Level -eq "WARN") { Write-Host $line }
}

function Get-UniqueDestinationPath {
    param([string]$DestDir, [string]$FileName)
    $dest = Join-Path $DestDir $FileName
    if (-not (Test-Path $dest)) { return $dest }
    $baseName = [System.IO.Path]::GetFileNameWithoutExtension($FileName)
    $ext = [System.IO.Path]::GetExtension($FileName)
    $i = 1
    do {
        $dest = Join-Path $DestDir ($baseName + "_$i" + $ext)
        $i++
    } while (Test-Path $dest)
    return $dest
}

function Move-FileSafe {
    param([string]$From, [string]$To, [string]$Reason = "move")
    if ($script:DryRun) {
        Write-Log "DRY-RUN: $Reason '$From' -> '$To'" "INFO"
        return $true
    }
    try {
        $parent = Split-Path $To -Parent
        if (-not (Test-Path $parent)) { New-Item -ItemType Directory -Path $parent -Force | Out-Null }
        Move-Item -LiteralPath $From -Destination $To -Force -ErrorAction Stop
        return $true
    } catch {
        Write-Log "Move error: $From -> $To : $_" "ERROR"
        return $false
    }
}

# --- Создание структуры папок на целевом диске ---
function Ensure-TargetFolders {
    foreach ($name in $script:Folders.Keys) {
        $path = Join-Path $script:TargetBase $name
        if (-not (Test-Path $path)) {
            if (-not $script:DryRun) { New-Item -ItemType Directory -Path $path -Force | Out-Null }
            Write-Log "Folder created: $path" "INFO"
        }
    }
}

# --- Поиск дубликатов по размеру + хешу (SHA256) ---
function Get-DuplicateSet {
    param([System.IO.FileInfo[]]$Files)
    $bySize = $Files | Group-Object -Property Length
    $duplicatePaths = [System.Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
    foreach ($group in $bySize) {
        if ($group.Count -lt 2) { continue }
        $hashToFirst = @{}
        foreach ($f in $group.Group) {
            try {
                $hash = (Get-FileHash -LiteralPath $f.FullName -Algorithm SHA256 -ErrorAction Stop).Hash
                if ($hashToFirst.ContainsKey($hash)) {
                    $duplicatePaths.Add($f.FullName) | Out-Null
                } else {
                    $hashToFirst[$hash] = $f.FullName
                }
            } catch {
                Write-Log "Hash failed: $($f.FullName) - $_" "WARN"
            }
        }
    }
    return $duplicatePaths
}

# --- Точка входа ---
$logHeader = "=== Organize Downloads v0.2 === Source: $($script:SourceBase) Target: $($script:TargetBase) DryRun: $($script:DryRun) SkipDuplicates: $($script:SkipDuplicates) SkipAutoClean: $($script:SkipAutoClean)"
Write-Log $logHeader "INFO"

if (-not (Test-Path $script:SourceBase)) {
    Write-Log "Source folder not found: $script:SourceBase" "ERROR"
    exit 1
}

Ensure-TargetFolders

$files = Get-ChildItem -Path $script:SourceBase -File -ErrorAction SilentlyContinue | Where-Object { $_.Name -ne "desktop.ini" }
if (-not $files) {
    Write-Log "No files to process in $script:SourceBase" "INFO"
} else {
    $duplicatePaths = $null
    if (-not $script:SkipDuplicates -and $files.Count -gt 0) {
        $duplicatePaths = Get-DuplicateSet -Files @($files)
        Write-Log "Duplicates found (by hash): $($duplicatePaths.Count)" "INFO"
    }

    foreach ($file in $files) {
        $fullName = $file.FullName
        if ($duplicatePaths -and $duplicatePaths.Contains($fullName)) {
            $destDir = Join-Path $script:TargetBase "_Duplicates"
            $destPath = Get-UniqueDestinationPath -DestDir $destDir -FileName $file.Name
            if (Move-FileSafe -From $fullName -To $destPath -Reason "duplicate") {
                Write-Log "Duplicate moved: $($file.Name) -> _Duplicates" "INFO"
            }
            continue
        }

        $ext = $file.Extension.ToLowerInvariant()
        $moved = $false

        # .md с google/gemini/gpt/chat в имени -> chat_export (на целевом диске)
        if ($ext -eq ".md" -and $file.Name -imatch $script:ChatExportPattern) {
            $destDir = Join-Path $script:TargetBase "chat_export"
            $destPath = Get-UniqueDestinationPath -DestDir $destDir -FileName $file.Name
            if (Move-FileSafe -From $fullName -To $destPath -Reason "chat_export") {
                Write-Log "Move: $($file.Name) -> chat_export" "INFO"
                $moved = $true
            }
        }

        if (-not $moved) {
            foreach ($folder in $script:Folders.Keys) {
                if ($folder -in "Other", "chat_export", "_Quarantine", "_Duplicates") { continue }
                if ($script:Folders[$folder] -contains $ext) {
                    $destDir = Join-Path $script:TargetBase $folder
                    $destPath = Get-UniqueDestinationPath -DestDir $destDir -FileName $file.Name
                    if (Move-FileSafe -From $fullName -To $destPath -Reason $folder) {
                        Write-Log "Move: $($file.Name) -> $folder" "INFO"
                        $moved = $true
                    }
                    break
                }
            }
        }

        if (-not $moved) {
            $destDir = Join-Path $script:TargetBase "Other"
            $destPath = Get-UniqueDestinationPath -DestDir $destDir -FileName $file.Name
            if (Move-FileSafe -From $fullName -To $destPath -Reason "Other") {
                Write-Log "Move: $($file.Name) -> Other" "INFO"
            }
        }
    }
}

# --- Автоочистка: старые установщики в целевой папке Installers -> _Quarantine ---
if (-not $script:SkipAutoClean -and (Test-Path (Join-Path $script:TargetBase "Installers"))) {
    $installersDir = Join-Path $script:TargetBase "Installers"
    $cutoff = (Get-Date).AddDays(-$script:OldInstallerDays)
    $oldInstallers = Get-ChildItem -Path $installersDir -File -ErrorAction SilentlyContinue | Where-Object { $_.LastWriteTime -lt $cutoff }
    foreach ($f in $oldInstallers) {
        $destPath = Get-UniqueDestinationPath -DestDir (Join-Path $script:TargetBase "_Quarantine") -FileName $f.Name
        if (Move-FileSafe -From $f.FullName -To $destPath -Reason "old_installer_quarantine") {
            Write-Log "Auto-clean: old installer (>$($script:OldInstallerDays) days) -> _Quarantine: $($f.Name)" "INFO"
        }
    }
}

Write-Log "=== Done ===" "INFO"
Write-Host "Done. Target: $($script:TargetBase); Log: $($script:LogPath)"
