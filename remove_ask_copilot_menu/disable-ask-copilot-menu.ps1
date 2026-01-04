# このスクリプトは「Copilot に聞く」コンテキストメニュー項目を非表示にするためのブロック値を登録します。
$registryPath = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Shell Extensions'
$blockedKeyPath = Join-Path -Path $registryPath -ChildPath 'Blocked'
$valueName = '{CB3B0003-8088-4EDE-8769-8B354AB2FF8C}'
$valueData = 'Ask Copilot'

$principal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    throw "Administrator privileges are required to write to HKLM. Please re-run this script as admin."
}

if (-not (Test-Path -Path $blockedKeyPath)) {
    New-Item -Path $blockedKeyPath -Force | Out-Null
}

New-ItemProperty -Path $blockedKeyPath -Name $valueName -PropertyType String -Value $valueData -Force | Out-Null
Write-Output "Registry value $valueName created/updated. 'Ask Copilot' context menu entry should now be hidden."
