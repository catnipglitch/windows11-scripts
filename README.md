# Windows11-scripts

Windows 11 向けの PowerShell スクリプトをまとめたリポジトリです。検索挙動の調整や Bluetooth ハンズフリー制御など、日常運用のちょっとした手間を減らすツールを収録しています。

## 環境
- Windows 11
- PowerShell 5.1 または PowerShell 7

## セットアップ
- スクリプトを実行する端末で実行ポリシーを確認し、必要に応じて Bypass などに設定する
- 管理者権限が必要なスクリプトは PowerShell を管理者として起動してから実行する

## 使い方
- 各スクリプトの詳細な使い方はサブフォルダの README を参照する
- 実行前に内容を確認し、必要に応じてバックアップを取得する

## プロジェクト構成
- BingBlocker: 検索ボックスの Bing 結果を無効化するレジストリ操作ツール
- bluetooth_handsfree_toggle: Bluetooth ハンズフリー (HFP) の有効/無効切り替えスクリプト
- file-organizer: 日付別フォルダへファイルを整理するスクリプトを収録
- PowerShell: 追加スクリプト格納用フォルダ
- remove_ask_copilot_menu: コンテキストメニューの「Copilot に聞く」を制御するスクリプト

## サブフォルダ README へのリンク集
- [BingBlocker/README.md](BingBlocker/README.md)
- [bluetooth_handsfree_toggle/README.md](bluetooth_handsfree_toggle/README.md)
- [remove_ask_copilot_menu/README.md](remove_ask_copilot_menu/README.md)