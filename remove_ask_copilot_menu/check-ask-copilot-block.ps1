# このスクリプトは「Copilot に聞く」コンテキストメニューのブロック設定が存在するか確認します。
$registryPath = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Shell Extensions'
$blockedKeyPath = Join-Path -Path $registryPath -ChildPath 'Blocked'
$valueName = '{CB3B0003-8088-4EDE-8769-8B354AB2FF8C}'
$expectedData = 'Ask Copilot'

if (-not (Test-Path -Path $blockedKeyPath)) {
    Write-Output "Blocked key not found. 'Ask Copilot' context menu entry is still enabled."
    return
}

try {
    $currentValue = Get-ItemProperty -Path $blockedKeyPath -Name $valueName -ErrorAction Stop | Select-Object -ExpandProperty $valueName
}
catch {
    Write-Output "Registry value $valueName not found. 'Ask Copilot' context menu entry is still enabled."
    return
}

if ($currentValue -eq $expectedData) {
    Write-Output "Registry value exists with expected data. 'Ask Copilot' context menu entry should be hidden."
}
else {
    Write-Output "Registry value exists but data differs: $currentValue"
}
