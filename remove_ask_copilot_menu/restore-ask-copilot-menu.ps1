# このスクリプトは登録済みの「Copilot に聞く」ブロック値を削除して右クリック項目を復活させます。
$registryPath = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Shell Extensions'
$blockedKeyPath = Join-Path -Path $registryPath -ChildPath 'Blocked'
$valueName = '{CB3B0003-8088-4EDE-8769-8B354AB2FF8C}'

$principal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    throw "Administrator privileges are required to write to HKLM. Please re-run this script as admin."
}

if (-not (Test-Path -Path $blockedKeyPath)) {
    Write-Output "Blocked key is not present. Nothing to remove."
    return
}

try {
    Remove-ItemProperty -Path $blockedKeyPath -Name $valueName -ErrorAction Stop
    Write-Output "Registry value $valueName removed. 'Ask Copilot' context menu entry will reappear after Explorer refresh."
}
catch {
    Write-Output "Registry value $valueName was not found. Nothing to remove."
}
