# API Key Validator

OpenAI / Anthropic (Claude) / Google Gemini / OpenRouter の API キーをまとめて検証する
PowerShell GUI スクリプトです。

## 特徴

- 各サービスの API キーを最大 3 件ずつ入力して一括チェック
- 目隠し入力と Show/Hide 切り替え
- 401/403/429 などの状態に応じた結果表示
- 追加インストール不要（System.Windows.Forms）

## 動作環境

- Windows 11
- PowerShell 5.1+ または PowerShell 7+ (pwsh)

## 使い方

1. `api-keys-validator.ps1` を実行します。
2. 各サービスの API キーを入力します（未入力はスキップ）。
3. `Check All` を押して検証します。
4. `Clear All` で入力と結果をリセットできます。

## 注意事項

- ネットワーク接続が必要です。
- レート制限中 (429) の場合は「有効だが制限中」と表示されます。
- 企業環境のプロキシや TLS 設定によっては接続に失敗する場合があります。
