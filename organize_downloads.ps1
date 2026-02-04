# Установить UTF-8 для текущей сессии
$OutputEncoding = [System.Text.Encoding]::UTF8
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# Organize C:\Users\Darkover\Downloads by file type
$base = "C:\Users\Darkover\Downloads"
Set-Location $base

$folders = @{
    "Installers" = @(".exe", ".msi")
    "Images"     = @(".png", ".jpg", ".jpeg", ".gif", ".webp", ".bmp", ".ico")
    "Videos"     = @(".mp4", ".mkv", ".avi", ".mov", ".wmv", ".webm")
    "Archives"   = @(".zip", ".7z", ".rar", ".tar", ".gz")
    "Documents"  = @(".txt", ".xlsx", ".xls", ".pdf", ".docx", ".doc", ".md")
    "Other"      = @()  # everything else
}

# Create folders
foreach ($name in $folders.Keys) {
    $path = Join-Path $base $name
    if (-not (Test-Path $path)) { New-Item -ItemType Directory -Path $path -Force | Out-Null }
}

# Get all files (not directories), exclude desktop.ini
$files = Get-ChildItem -Path $base -File | Where-Object { $_.Name -ne "desktop.ini" }

foreach ($file in $files) {
    $ext = $file.Extension.ToLowerInvariant()
    $moved = $false

    foreach ($folder in $folders.Keys) {
        if ($folder -eq "Other") { continue }
        if ($folders[$folder] -contains $ext) {
            $destDir = Join-Path $base $folder
            $destPath = Join-Path $destDir $file.Name
            if (Test-Path $destPath) {
                # Avoid overwrite: add number
                $baseName = [System.IO.Path]::GetFileNameWithoutExtension($file.Name)
                $i = 1
                while (Test-Path $destPath) {
                    $destPath = Join-Path $destDir ($baseName + "_$i" + $file.Extension)
                    $i++
                }
            }
            Move-Item -LiteralPath $file.FullName -Destination $destPath -Force -ErrorAction SilentlyContinue
            $moved = $true
            break
        }
    }

    if (-not $moved) {
        $destDir = Join-Path $base "Other"
        $destPath = Join-Path $destDir $file.Name
        if (Test-Path $destPath) {
            $baseName = [System.IO.Path]::GetFileNameWithoutExtension($file.Name)
            $i = 1
            while (Test-Path $destPath) {
                $destPath = Join-Path $destDir ($baseName + "_$i" + $file.Extension)
                $i++
            }
        }
        Move-Item -LiteralPath $file.FullName -Destination $destPath -Force -ErrorAction SilentlyContinue
    }
}

Write-Host "Done. Folders: Installers, Images, Videos, Archives, Documents, Other"
