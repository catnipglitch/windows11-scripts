<#
============================================================
check-handsfree.ps1
============================================================

【要件】
- Windows 11 上で Bluetooth の Hands-Free (HFP) 関連デバイスを検出し、
  現在の状態（ON / OFF）を一覧表示すること。
- 読み取り専用であること（Enable/Disable 等の変更は一切行わない）。
- 汎用的に使えること（特定機種の InstanceId を固定しない）。
- 対象機器をデバイス名で絞り込めること（例: WH-CH720N のみ表示）。

【仕様】
- PnP デバイス一覧から Hands-Free 関連と思われるものを抽出する。
  抽出条件は以下のいずれかを満たすこと：
  1) InstanceId が "BTHHFENUM\BTHHFPAUDIO*" に一致する（Hands-Free Audio 本体）
  2) FriendlyName に "Hands-Free" または "AG Audio" を含む
- Status が "OK" の場合を ON、それ以外を OFF として表示する。
- 管理者権限がなくても実行可能。
  ただし、管理者でない場合は Warning を出す（読み取り自体は継続する）。

【使い方】
1) すべての Hands-Free 関連デバイスを表示:
  .\check-handsfree.ps1

2) 特定デバイス（例: WH-CH720N）に絞る:
  .\check-handsfree.ps1 -DeviceName "WH-CH720N"

3) 例（デバイス名が日本語/英語混在の場合）
  .\check-handsfree.ps1 -DeviceName "JBL"

【備考】
- Bluetoothデバイスは再接続や切替中に Status が Unknown / Error になることがある。
  それ自体は異常とは限らないため、状態確認は複数回行うこと。
- 本スクリプトは「GUI上のサービス（ハンズフリーテレフォニー）チェック状態」ではなく、
  PnPデバイスの状態（OSが実際に提供している HFP関連デバイス）を観測する。
============================================================
#>

param(
  [string]$DeviceName = ""
)

# 管理者判定（警告のみ）
$principal = New-Object Security.Principal.WindowsPrincipal(
  [Security.Principal.WindowsIdentity]::GetCurrent()
)
if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
  Write-Warning "Not running as Administrator. (Read-only check will continue.)"
}

Write-Host "=== Hands-Free (HFP) device status ===" -ForegroundColor Cyan
if ($DeviceName) {
  Write-Host ("Filter DeviceName: " + $DeviceName) -ForegroundColor DarkCyan
}

# Hands-Free関連デバイス抽出
$devices = Get-PnpDevice | Where-Object {
  $_.InstanceId -like "BTHHFENUM\BTHHFPAUDIO*" -or
  $_.FriendlyName -match "Hands-Free|AG Audio"
}

# デバイス名で絞る（FriendlyNameベース）
if ($DeviceName) {
  $escaped = [regex]::Escape($DeviceName)
  $devices = $devices | Where-Object { $_.FriendlyName -match $escaped }
}

if (-not $devices) {
  Write-Warning "No matching Hands-Free devices found."
  exit 0
}

# 表示用整形
$devices | ForEach-Object {
  $onoff = if ($_.Status -eq "OK") { "ON " } else { "OFF" }
  [PSCustomObject]@{
    State        = $onoff
    Status       = $_.Status
    FriendlyName = $_.FriendlyName
    InstanceId   = $_.InstanceId
  }
} | Sort-Object FriendlyName, InstanceId | Format-Table -Auto

# 最終サマリ（HFP本体が ON なら Hands-Free overall: ON）
$hfpCore = $devices | Where-Object { $_.InstanceId -like "BTHHFENUM\BTHHFPAUDIO*" }
$hfOn = $hfpCore | Where-Object { $_.Status -eq "OK" }

if ($hfOn) {
  Write-Host "`nHands-Free overall: ON" -ForegroundColor Green
}
else {
  Write-Host "`nHands-Free overall: OFF" -ForegroundColor Yellow
}
