<#
このスクリプトは、指定フォルダ内のファイルを更新日時の年月単位 (YYYY-MM) フォルダへ移動します。
存在しない年月フォルダは自動作成し、0 バイトのファイルは破損扱いで移動しません。
同名ファイルがある場合は連番でリネームし、フォルダ未指定時は選択ダイアログを表示します (STA 実行が必要)。
#>

param(
    [Parameter(Position = 0)]
    [string]$Path,

    [switch]$Recurse
)

function Select-Folder {
    Add-Type -AssemblyName System.Windows.Forms

    $dialog = New-Object System.Windows.Forms.FolderBrowserDialog
    $dialog.Description = "仕分け対象フォルダを選んでください"
    $dialog.ShowNewFolderButton = $true

    $result = $dialog.ShowDialog()
    if ($result -eq [System.Windows.Forms.DialogResult]::OK) {
        return $dialog.SelectedPath
    }

    return $null
}

if (-not $PSBoundParameters.ContainsKey('Path') -or [string]::IsNullOrWhiteSpace($Path)) {
    if ([System.Threading.Thread]::CurrentThread.ApartmentState -ne [System.Threading.ApartmentState]::STA) {
        throw "フォルダ選択ダイアログを使うには、PowerShell を -STA 付きで実行してください。"
    }

    $Path = Select-Folder
    if (-not $Path) {
        Write-Host "キャンセルされました。" -ForegroundColor Yellow
        return
    }
}

# Normalize and validate input directory.
if (-not (Test-Path -LiteralPath $Path -PathType Container)) {
    throw "Path '$Path' does not exist or is not a directory."
}
$root = (Resolve-Path -LiteralPath $Path).Path

function Get-UniqueDestination {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Candidate
    )

    $directory = [System.IO.Path]::GetDirectoryName($Candidate)
    $name = [System.IO.Path]::GetFileNameWithoutExtension($Candidate)
    $ext = [System.IO.Path]::GetExtension($Candidate)

    $unique = $Candidate
    $suffix = 1
    while (Test-Path -LiteralPath $unique) {
        $unique = Join-Path -Path $directory -ChildPath ("{0} ({1}){2}" -f $name, $suffix, $ext)
        $suffix++
    }

    return $unique
}

$files = Get-ChildItem -LiteralPath $root -File -Recurse:$Recurse
$moved = 0
$skippedZero = 0
$skippedAlreadyPlaced = 0

foreach ($file in $files) {
    if ($file.Length -eq 0) {
        $skippedZero++
        continue
    }

    $stamp = $file.LastWriteTime
    $targetFolder = Join-Path -Path $root -ChildPath ('{0:yyyy-MM}' -f $stamp)

    if (-not (Test-Path -LiteralPath $targetFolder -PathType Container)) {
        New-Item -ItemType Directory -Path $targetFolder -Force | Out-Null
    }

    # Skip if the file is already in the correct target folder.
    $currentFolder = [System.IO.Path]::GetDirectoryName($file.FullName)
    if ([System.IO.Path]::GetFullPath($currentFolder) -eq [System.IO.Path]::GetFullPath($targetFolder)) {
        $skippedAlreadyPlaced++
        continue
    }

    $destination = Join-Path -Path $targetFolder -ChildPath $file.Name
    $destination = Get-UniqueDestination -Candidate $destination

    Move-Item -LiteralPath $file.FullName -Destination $destination
    $moved++
}

Write-Host "Processed $($files.Count) files." -ForegroundColor Cyan
Write-Host "Moved: $moved" -ForegroundColor Green
Write-Host "Skipped (zero bytes): $skippedZero" -ForegroundColor Yellow
Write-Host "Skipped (already in target): $skippedAlreadyPlaced" -ForegroundColor Yellow
