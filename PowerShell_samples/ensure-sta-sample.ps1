<#
.SYNOPSIS
 サンプル: STA (Single-Threaded Apartment) が必要な処理を行うテストスクリプト。

.DESCRIPTION
 PowerShell の現在のスレッドの ApartmentState が `STA` でない場合、
 自分自身を `-STA` オプション付きで再起動します。WPF や一部の COM API
（たとえば `System.Windows.MessageBox`）は STA スレッドが必要です。

 実行例:
   pwsh -File .\ensure-sta.ps1

 パラメーター:
   -StaChild: スクリプトが再起動後に子プロセスであることを示すフラグ。
#>

param(
    [switch]$StaChild # 再起動して来た子プロセスかどうかを判定するためのフラグ
)

# 現在の PowerShell ホストの ApartmentState を取得します（MTA か STA）。
$apartment = $Host.Runspace.ApartmentState

# ApartmentState が STA でない（＝STA が必要な API を呼べない）場合、
# 自分自身を `-STA` で再起動します。再起動後に無限ループにならないよう、
# 再起動時は `-StaChild` スイッチを付けて識別します。
if ($apartment -ne 'STA' -and -not $StaChild) {
    Start-Process pwsh `
        -ArgumentList @(
        '-STA',                 # 再起動先のプロセスを STA モードで起動
        '-File', "`"$PSCommandPath`"", # 現在のスクリプトファイルを指定
        '-StaChild'             # 再起動済みの子プロセスであることを示す
    )
    # 親プロセスは終了して、子プロセスに処理を渡す
    exit
}

# ===== STA 必須処理 =====
# ここから下の処理は STA スレッド上で実行されることを想定しています。

# WPF の型（PresentationFramework）を読み込みます。これにより
# `System.Windows.MessageBox` などが利用可能になります。
Add-Type -AssemblyName PresentationFramework

# MessageBox は UI コンポーネントのため STA を要求します。
[System.Windows.MessageBox]::Show(
    "Hello from STA!",   # 表示するメッセージ
    "STA MessageBox"     # ウィンドウのタイトル
)
