# 「Copilot に聞く」コンテキストメニュー制御

このフォルダーには、Windows 11 の右クリックメニューから「Copilot に聞く」を非表示にするためのレジストリエントリを管理する PowerShell スクリプトが含まれています。

## ファイル構成
| 名前                           | 概要                                                       |
| ------------------------------ | ---------------------------------------------------------- |
| `check-ask-copilot-block.ps1`  | `Shell Extensions\Blocked` に対象の値があるか確認します。  |
| `disable-ask-copilot-menu.ps1` | 文字列値を作成または更新し、メニュー項目を非表示にします。 |
| `restore-ask-copilot-menu.ps1` | 作成した文字列値を削除して、メニュー項目を元に戻します。   |

## 使い方
- `HKLM` に書き込む登録/削除スクリプトは、必ず管理者権限の PowerShell で実行してください。
- `./disable-ask-copilot-menu.ps1` を実行して項目を隠し、エクスプローラー再起動またはサインアウト/サインインで反映させます。
- 状態を確認したいときは `./check-ask-copilot-block.ps1` を実行します。
- 項目を復活させたい場合は `./restore-ask-copilot-menu.ps1` を実行します。

## 備考
- 操作対象は `HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Shell Extensions\Blocked` 配下の CLSID `{CB3B0003-8088-4EDE-8769-8B354AB2FF8C}` のみです。
- 再起動は不要ですが、エクスプローラーの再起動を行わないと変更が即時反映されません。
