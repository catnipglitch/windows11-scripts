# Windows11-scripts

Windows 11 向けの PowerShell スクリプトをまとめたリポジトリです。

## 環境

- Windows 11
- PowerShell 7 (pwsh) 

## 使い方

- 各サブフォルダの README にスクリプトごとの手順と注意事項をまとめています。
- 実行前にコードを確認し、必要に応じてバックアップを取得してください。

## スクリプト色々

- api-key-validator: 複数サービスの API キーを GUI で一括検証するツール
- BingBlocker: 検索ボックスの Bing 結果を無効化するレジストリ操作ツール
- bluetooth_handsfree_toggle: Bluetooth ハンズフリー (HFP) の有効/無効切り替えスクリプト
- file-organizer: 日付別フォルダへファイルを整理するスクリプト
- PowerShell_samples: サンプルやテンプレートスクリプト
- remove_ask_copilot_menu: コンテキストメニューの「Copilot に聞く」を制御するスクリプト
- win11_env_settings: 環境変数を一覧・編集する GUI スクリプト（PowerShell/WPF）

## サブフォルダ README へのリンク集

- [api-key-validator/README.md](api-key-validator/README.md)
- [BingBlocker/README.md](BingBlocker/README.md)
- [bluetooth_handsfree_toggle/README.md](bluetooth_handsfree_toggle/README.md)
- [remove_ask_copilot_menu/README.md](remove_ask_copilot_menu/README.md)
- [win11_env_settings/README.md](win11_env_settings/README.md)

## 注意事項

- スクリプトはユーザー環境や権限によって動作が異なります。
- 環境変数やレジストリを編集するスクリプトは慎重に扱い、必要に応じてバックアップを取ってください。
