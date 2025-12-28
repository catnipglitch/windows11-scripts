<#
============================================================
toggle-handsfree.ps1
============================================================

【要件】
- Windows 11 上で Bluetooth の Hands-Free (HFP) を ON / OFF / TOGGLE できること
- 汎用的に使えること（デバイス固有 InstanceId を固定しない）
- 安全性を確保すること
  - 対象デバイス名で絞り込めること（誤爆防止のため必須）
  - 一時的にエラーが出ても最終状態で成功判定すること
- 実行後に「最終状態（Hands-Free overall: ON/OFF）」を必ず表示すること

【仕様】
- Mode:
  - status : 状態表示のみ
  - off    : Hands-Free を無効化
  - on     : Hands-Free を有効化
  - toggle : 現在状態を反転
- DeviceName:
  - 対象Bluetooth機器名（例: "WH-CH720N"）
  - FriendlyName にこの文字列を含む Hands-Free 関連デバイスのみを対象にする
- Hands-Free 関連デバイス抽出条件:
  1) InstanceId が "BTHHFENUM\BTHHFPAUDIO*"（HFP本体：最優先）
  2) FriendlyName に "Hands-Free" または "AG Audio" を含む（補助）
- Status = "OK" を ON と判定。それ以外を OFF と判定。
- Enable/Disable は環境により一時的に失敗（HRESULT 0x80041001 等）することがあるため、
  実行後に状態再取得を複数回行い、最終状態で成功判定する（リトライ）。

【使い方】
※変更系は管理者権限が必須

1) 状態表示（管理者不要でも動くが推奨は管理者）
  .\toggle-handsfree.ps1 -Mode status -DeviceName "WH-CH720N"

2) Hands-Free OFF（管理者必須）
  .\toggle-handsfree.ps1 -Mode off -DeviceName "WH-CH720N"

3) Hands-Free ON（管理者必須）
  .\toggle-handsfree.ps1 -Mode on -DeviceName "WH-CH720N"

4) トグル（管理者必須）
  .\toggle-handsfree.ps1 -Mode toggle -DeviceName "WH-CH720N"

【備考】
- 本スクリプトは「コントロールパネルの Bluetooth サービス（ハンズフリーテレフォニー）チェック」
  を直接 OFF にするものではない。
  PnP レベルの Hands-Free 関連デバイスを有効/無効化することで、HFP利用を抑制する。
- Windows は Bluetooth の再接続や切替中に Status が Unknown / Error となることがある。
  これ自体は異常とは限らないため、リトライで最終状態を評価する。
============================================================
#>

param(
  [ValidateSet("on", "off", "toggle", "status")]
  [string]$Mode = "status",

  [Parameter(Mandatory = $true)]
  [string]$DeviceName
)

# ----------------------------
# 管理者権限チェック（変更時のみ必須）
# ----------------------------
$principal = New-Object Security.Principal.WindowsPrincipal(
  [Security.Principal.WindowsIdentity]::GetCurrent()
)
$IsAdmin = $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if ($Mode -ne "status" -and -not $IsAdmin) {
  Write-Error "Run this script as Administrator for Mode: $Mode"
  exit 1
}

# ----------------------------
# Hands-Free関連デバイス取得
# ----------------------------
function Get-HfpDevices {
  param([string]$DeviceName)

  $all = Get-PnpDevice | Where-Object {
    $_.InstanceId -like "BTHHFENUM\BTHHFPAUDIO*" -or
    $_.FriendlyName -match "Hands-Free|AG Audio"
  }

  $escaped = [regex]::Escape($DeviceName)
  $filtered = $all | Where-Object { $_.FriendlyName -match $escaped }

  return $filtered
}

# ----------------------------
# 表示
# ----------------------------
function Show-State {
  param([string]$DeviceName, $devices)

  Write-Host "`nCurrent Hands-Free status for: $DeviceName" -ForegroundColor Cyan

  if (-not $devices) {
    Write-Warning "No matching Hands-Free devices found for DeviceName: '$DeviceName'"
    return
  }

  $devices | ForEach-Object {
    $onoff = if ($_.Status -eq "OK") { "ON " } else { "OFF" }
    [PSCustomObject]@{
      State        = $onoff
      Status       = $_.Status
      FriendlyName = $_.FriendlyName
      InstanceId   = $_.InstanceId
    }
  } | Sort-Object FriendlyName, InstanceId | Format-Table -Auto
}

# ----------------------------
# 最終サマリ
# ----------------------------
function Show-Overall {
  param($devices)

  $hfpCore = $devices | Where-Object { $_.InstanceId -like "BTHHFENUM\BTHHFPAUDIO*" }
  $hfOn = $hfpCore | Where-Object { $_.Status -eq "OK" }

  if ($hfOn) {
    Write-Host "`nHands-Free overall: ON" -ForegroundColor Green
  }
  else {
    Write-Host "`nHands-Free overall: OFF" -ForegroundColor Yellow
  }
}

# ----------------------------
# Safe 操作（最終状態確認付き）
# ----------------------------
function Safe-Disable {
  param(
    [string]$InstanceId,
    [int]$Retry = 6,
    [int]$WaitMs = 300
  )

  $before = Get-PnpDevice -InstanceId $InstanceId -ErrorAction SilentlyContinue
  if (-not $before) { return }
  if ($before.Status -ne "OK") { return }  # 既にOFF

  try {
    Disable-PnpDevice -InstanceId $InstanceId -Confirm:$false -ErrorAction Stop
  }
  catch {
    # 一時エラーは無視（後で状態確認する）
  }

  for ($i = 0; $i -lt $Retry; $i++) {
    Start-Sleep -Milliseconds $WaitMs
    $after = Get-PnpDevice -InstanceId $InstanceId -ErrorAction SilentlyContinue
    if (-not $after) { return }
    if ($after.Status -ne "OK") { return }  # OFFになったので成功
  }

  Write-Warning "Disable failed (final state still OK): $InstanceId"
}

function Safe-Enable {
  param(
    [string]$InstanceId,
    [int]$Retry = 6,
    [int]$WaitMs = 300
  )

  $before = Get-PnpDevice -InstanceId $InstanceId -ErrorAction SilentlyContinue
  if (-not $before) { return }
  if ($before.Status -eq "OK") { return }  # 既にON

  try {
    Enable-PnpDevice -InstanceId $InstanceId -Confirm:$false -ErrorAction Stop
  }
  catch {
    # 一時エラーは無視（後で状態確認する）
  }

  for ($i = 0; $i -lt $Retry; $i++) {
    Start-Sleep -Milliseconds $WaitMs
    $after = Get-PnpDevice -InstanceId $InstanceId -ErrorAction SilentlyContinue
    if (-not $after) { return }
    if ($after.Status -eq "OK") { return }  # ONになったので成功
  }

  Write-Warning "Enable failed (final state still not OK): $InstanceId"
}

# ----------------------------
# 実行
# ----------------------------
$devices = Get-HfpDevices -DeviceName $DeviceName
Show-State -DeviceName $DeviceName -devices $devices

if (-not $devices) {
  # 対象なしなら終了（安全）
  exit 0
}

if ($Mode -eq "status") {
  Show-Overall -devices $devices
  exit 0
}

# HFP本体（最優先）
$hfpCore = $devices | Where-Object { $_.InstanceId -like "BTHHFENUM\BTHHFPAUDIO*" }
# 補助（AudioEndpoint / AG Audio等）
$hfpAux = $devices | Where-Object { $_.InstanceId -notlike "BTHHFENUM\BTHHFPAUDIO*" }

# 現在がONかどうか（HFP本体がOKならONとみなす）
$hfOn = ($hfpCore | Where-Object { $_.Status -eq "OK" })

switch ($Mode) {

  "off" {
    Write-Host "`nTurning Hands-Free OFF..." -ForegroundColor Yellow

    # まずHFP本体を落とす
    $hfpCore | Where-Object { $_.Status -eq "OK" } | ForEach-Object {
      Safe-Disable -InstanceId $_.InstanceId
    }

    # 補助は落とせたら落とす（失敗しても続行）
    $hfpAux | Where-Object { $_.Status -eq "OK" } | ForEach-Object {
      Safe-Disable -InstanceId $_.InstanceId
    }
  }

  "on" {
    Write-Host "`nTurning Hands-Free ON..." -ForegroundColor Green

    # まずHFP本体を戻す
    $hfpCore | Where-Object { $_.Status -ne "OK" } | ForEach-Object {
      Safe-Enable -InstanceId $_.InstanceId
    }

    # 補助も戻す
    $hfpAux | Where-Object { $_.Status -ne "OK" } | ForEach-Object {
      Safe-Enable -InstanceId $_.InstanceId
    }
  }

  "toggle" {
    if ($hfOn) {
      Write-Host "`nToggle: ON -> OFF" -ForegroundColor Yellow

      $hfpCore | Where-Object { $_.Status -eq "OK" } | ForEach-Object {
        Safe-Disable -InstanceId $_.InstanceId
      }
      $hfpAux | Where-Object { $_.Status -eq "OK" } | ForEach-Object {
        Safe-Disable -InstanceId $_.InstanceId
      }

    }
    else {
      Write-Host "`nToggle: OFF -> ON" -ForegroundColor Green

      $hfpCore | Where-Object { $_.Status -ne "OK" } | ForEach-Object {
        Safe-Enable -InstanceId $_.InstanceId
      }
      $hfpAux | Where-Object { $_.Status -ne "OK" } | ForEach-Object {
        Safe-Enable -InstanceId $_.InstanceId
      }
    }
  }
}

# ----------------------------
# 最終状態表示（再取得）
# ----------------------------
Start-Sleep -Milliseconds 700
$devices = Get-HfpDevices -DeviceName $DeviceName
Show-State -DeviceName $DeviceName -devices $devices
Show-Overall -devices $devices
