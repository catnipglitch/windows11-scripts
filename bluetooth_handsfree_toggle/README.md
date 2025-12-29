# Bluetooth Hands-Free (HFP) を OFF/ON する

Bluetooth ヘッドセットの「Hands-Free（通話用 / HFP）」が録音・配信の音質を落とす/勝手に切り替わるのを避けるために、
Windows の PnP デバイスとして見える Hands-Free 関連デバイスを有効/無効化します。

このフォルダには2つの PowerShell スクリプト（本体）があります。
- `check-handsfree.ps1`：状態確認（読み取り専用）
- `toggle-handsfree.ps1`：Hands-Free を OFF/ON/TOGGLE（変更系。管理者権限（昇格）が必要）

サンプル（機種名入りの実行例）:
- `example.WH-CH720N-mode_off.ps1`
- `example.WH-CH720N-mode_on.ps1`

## 前提

- Windows 11
- PowerShell から実行
- **`toggle-handsfree.ps1` の `-Mode on/off/toggle` は管理者権限（管理者として実行）が必要**（`status` は不要）

## 状態確認とデバイス名の確認

すべて表示:

```powershell
.\check-handsfree.ps1
```

機種名で絞る（FriendlyName に含まれる文字列でマッチ）:

```powershell
.\check-handsfree.ps1 -DeviceName "WH-CH720N"
```

## 利用例

OBS などの配信/録音ソフト利用時に、Hands-Free（HFP）へ勝手に切り替わって音質が落ちる問題の回避を想定しています。

Hands-Free を使わない用途（録音・配信・ゲームなど）のときは OFF（管理者権限で実行）:

```powershell
.\toggle-handsfree.ps1 -Mode off -DeviceName "WH-CH720N"
```

Hands-Free を使うツール（例: Slack / Google Chat）を使う直前に ON（管理者権限で実行）:

```powershell
.\toggle-handsfree.ps1 -Mode on -DeviceName "WH-CH720N"
```

ワンキー運用なら toggle（管理者権限で実行）:

```powershell
.\toggle-handsfree.ps1 -Mode toggle -DeviceName "WH-CH720N"
```

## `toggle-handsfree.ps1` のモード

```text
status : 状態表示のみ（管理者不要）
off    : Hands-Free を無効化（管理者権限が必要）
on     : Hands-Free を有効化（管理者権限が必要）
toggle : 現在状態を反転（管理者権限が必要）
```

状態表示だけ（管理者不要）:

```powershell
.\toggle-handsfree.ps1 -Mode status -DeviceName "WH-CH720N"
```

## トラブルシュート

- `Run this script as Administrator for Mode: off/on/toggle` が出る
	- そのモードは管理者権限が必要です。PowerShell を「管理者として実行」で起動して実行してください。
- `No matching Hands-Free devices found` が出る
	- `-DeviceName` が FriendlyName に一致していません。
	- まず `check-handsfree.ps1` をフィルタなしで実行して、表示される名前に合わせてください。
- 一時的にエラーが出る / すぐ反映されない
	- Bluetooth の再接続や切替中は `Status` が不安定になることがあります。
	- `toggle-handsfree.ps1` は状態を再取得して最終状態を表示します（必要なら数回実行）。

## `ExecutionPolicy Bypass` で実行する場合（例）

実行ポリシーの都合で `./` 実行が弾かれる場合だけ、下記のように `-ExecutionPolicy Bypass` を付けて呼び出せます。

```powershell
powershell -ExecutionPolicy Bypass -File .\check-handsfree.ps1
powershell -ExecutionPolicy Bypass -File .\check-handsfree.ps1 -DeviceName "WH-CH720N"

powershell -ExecutionPolicy Bypass -File .\toggle-handsfree.ps1 -Mode status -DeviceName "WH-CH720N"
powershell -ExecutionPolicy Bypass -File .\toggle-handsfree.ps1 -Mode off    -DeviceName "WH-CH720N"
powershell -ExecutionPolicy Bypass -File .\toggle-handsfree.ps1 -Mode on     -DeviceName "WH-CH720N"
powershell -ExecutionPolicy Bypass -File .\toggle-handsfree.ps1 -Mode toggle -DeviceName "WH-CH720N"
```

## サンプル（機種名入り）

中身は `toggle-handsfree.ps1` を呼び出しているだけなので、お手持ちの機種名を自分の環境に合わせてください。

```powershell
powershell -ExecutionPolicy Bypass -File .\example.WH-CH720N-mode_off.ps1
powershell -ExecutionPolicy Bypass -File .\example.WH-CH720N-mode_on.ps1
```