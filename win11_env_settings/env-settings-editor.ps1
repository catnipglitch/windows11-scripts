<#
.SYNOPSIS
    Windows 11 環境変数エディタ (GUI)

.DESCRIPTION
    WPFを使用して、指定されたユーザー環境変数を一覧表示・編集するGUIツール。
    管理対象の環境変数はスクリプト内のテーブルで定義し、
    セキュリティ対策としてマスク表示機能を持つ。

.NOTES
    FileName:   env-settings-editor.ps1
    Author:     Generated for Windows 11
    Requires:   PowerShell 7.x (pwsh)
    
.EXAMPLE
    pwsh -File env-settings-editor.ps1
#>

#Requires -Version 7.0

# STAスレッドモードの確保
if ($Host.Runspace.ApartmentState -ne 'STA') {
    Write-Warning "このスクリプトはSTAモードで実行する必要があります。STAモードで再起動します..."
    Start-Process pwsh -ArgumentList "-STA", "-NoProfile", "-File", "`"$PSCommandPath`"" -Wait
    exit
}

Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase

#region テーブル定義: 管理対象環境変数
# 各行の先頭に # を付けることで、その環境変数を無効化（非表示）できます
$script:EnvVariableDefinitions = @(
    # OpenAI / OpenAI互換
    [PSCustomObject]@{ Name = 'OPENAI_API_KEY'; Description = 'OpenAI APIの認証キー'; IsMasked = $true; Scope = 'User' },
    # [PSCustomObject]@{ Name = 'OPENAI_ORG_ID'; Description = 'OpenAI組織ID'; IsMasked = $false; Scope = 'User' },
    # [PSCustomObject]@{ Name = 'OPENAI_BASE_URL'; Description = 'OpenAI APIのベースURL（互換API用）'; IsMasked = $false; Scope = 'User' },
    # [PSCustomObject]@{ Name = 'OPENAI_API_BASE'; Description = 'OpenAI APIベースURL（代替）'; IsMasked = $false; Scope = 'User' },
    # [PSCustomObject]@{ Name = 'OPENAI_API_VERSION'; Description = 'OpenAI APIバージョン'; IsMasked = $false; Scope = 'User' },
    
    # Azure OpenAI
    # [PSCustomObject]@{ Name = 'AZURE_OPENAI_API_KEY'; Description = 'Azure OpenAI Serviceの認証キー'; IsMasked = $true; Scope = 'User' },
    # [PSCustomObject]@{ Name = 'AZURE_OPENAI_ENDPOINT'; Description = 'Azure OpenAI Serviceのエンドポイント'; IsMasked = $false; Scope = 'User' },
    # [PSCustomObject]@{ Name = 'AZURE_OPENAI_DEPLOYMENT_NAME'; Description = 'Azure OpenAIデプロイメント名'; IsMasked = $false; Scope = 'User' },
    # [PSCustomObject]@{ Name = 'AZURE_OPENAI_API_VERSION'; Description = 'Azure OpenAI APIバージョン'; IsMasked = $false; Scope = 'User' },
    
    # Anthropic (Claude)
    [PSCustomObject]@{ Name = 'ANTHROPIC_API_KEY'; Description = 'Anthropic Claude APIの認証キー'; IsMasked = $true; Scope = 'User' },
    # [PSCustomObject]@{ Name = 'ANTHROPIC_BASE_URL'; Description = 'Anthropic APIのベースURL'; IsMasked = $false; Scope = 'User' },
    
    # Google (Gemini / Vertex AI)
    [PSCustomObject]@{ Name = 'GOOGLE_API_KEY'; Description = 'Google AI (Gemini) APIキー'; IsMasked = $true; Scope = 'User' },
    # [PSCustomObject]@{ Name = 'GOOGLE_APPLICATION_CREDENTIALS'; Description = 'Google Cloud認証情報JSONファイルパス'; IsMasked = $false; Scope = 'User' },
    # [PSCustomObject]@{ Name = 'VERTEX_PROJECT'; Description = 'Google Vertex AI プロジェクトID'; IsMasked = $false; Scope = 'User' },
    # [PSCustomObject]@{ Name = 'VERTEX_LOCATION'; Description = 'Google Vertex AI リージョン'; IsMasked = $false; Scope = 'User' },
    # [PSCustomObject]@{ Name = 'GOOGLE_CLOUD_PROJECT'; Description = 'Google Cloud プロジェクトID'; IsMasked = $false; Scope = 'User' },
    # [PSCustomObject]@{ Name = 'GOOGLE_CLOUD_LOCATION'; Description = 'Google Cloud リージョン'; IsMasked = $false; Scope = 'User' },
    
    # Gemini モデル指定・実行系
    # [PSCustomObject]@{ Name = 'GEMINI_MODEL'; Description = 'Gemini モデル名'; IsMasked = $false; Scope = 'User' },
    # [PSCustomObject]@{ Name = 'GEMINI_MODEL_ID'; Description = 'Gemini モデルID'; IsMasked = $false; Scope = 'User' },
    # [PSCustomObject]@{ Name = 'GEMINI_MAX_TOKENS'; Description = 'Gemini 最大トークン数'; IsMasked = $false; Scope = 'User' },
    
    # AWS Bedrock
    # [PSCustomObject]@{ Name = 'AWS_ACCESS_KEY_ID'; Description = 'AWSアクセスキーID'; IsMasked = $true; Scope = 'User' },
    # [PSCustomObject]@{ Name = 'AWS_SECRET_ACCESS_KEY'; Description = 'AWSシークレットアクセスキー'; IsMasked = $true; Scope = 'User' },
    # [PSCustomObject]@{ Name = 'AWS_SESSION_TOKEN'; Description = 'AWSセッショントークン（一時的な認証）'; IsMasked = $true; Scope = 'User' },
    # [PSCustomObject]@{ Name = 'AWS_DEFAULT_REGION'; Description = 'AWSデフォルトリージョン'; IsMasked = $false; Scope = 'User' },
    
    # Cohere
    # [PSCustomObject]@{ Name = 'COHERE_API_KEY'; Description = 'Cohere APIの認証キー'; IsMasked = $true; Scope = 'User' },
    
    # Mistral
    # [PSCustomObject]@{ Name = 'MISTRAL_API_KEY'; Description = 'Mistral AIの認証キー'; IsMasked = $true; Scope = 'User' },
    
    # Hugging Face
    # [PSCustomObject]@{ Name = 'HUGGINGFACE_API_KEY'; Description = 'Hugging Face APIキー'; IsMasked = $true; Scope = 'User' },
    # [PSCustomObject]@{ Name = 'HF_HOME'; Description = 'Hugging Faceホームディレクトリ'; IsMasked = $false; Scope = 'User' },
    # [PSCustomObject]@{ Name = 'HF_TOKEN'; Description = 'Hugging Face認証トークン'; IsMasked = $true; Scope = 'User' },
    
    # Ollama / ローカルLLM
    # [PSCustomObject]@{ Name = 'TRANSFORMERS_CACHE'; Description = 'Transformersモデルキャッシュディレクトリ'; IsMasked = $false; Scope = 'User' },
    # [PSCustomObject]@{ Name = 'OLLAMA_HOST'; Description = 'Ollamaサーバーのホストアドレス'; IsMasked = $false; Scope = 'User' },
    # [PSCustomObject]@{ Name = 'OLLAMA_MODELS'; Description = 'Ollamaモデル保存ディレクトリ'; IsMasked = $false; Scope = 'User' },
    # [PSCustomObject]@{ Name = 'OLLAMA_KEEP_ALIVE'; Description = 'Ollamaモデル保持時間'; IsMasked = $false; Scope = 'User' },
    
    # LangChain / LLM共通ミドルウェア
    # [PSCustomObject]@{ Name = 'LANGCHAIN_API_KEY'; Description = 'LangChain APIキー'; IsMasked = $true; Scope = 'User' },
    # [PSCustomObject]@{ Name = 'LANGCHAIN_TRACING_V2'; Description = 'LangChainトレーシング有効化フラグ'; IsMasked = $false; Scope = 'User' },
    # [PSCustomObject]@{ Name = 'LANGCHAIN_PROJECT'; Description = 'LangChainプロジェクト名'; IsMasked = $false; Scope = 'User' },
    # [PSCustomObject]@{ Name = 'LANGCHAIN_ENDPOINT'; Description = 'LangChainエンドポイントURL'; IsMasked = $false; Scope = 'User' },
    
    # LlamaIndex
    # [PSCustomObject]@{ Name = 'LLAMA_INDEX_CACHE_DIR'; Description = 'LlamaIndexキャッシュディレクトリ'; IsMasked = $false; Scope = 'User' },
    # [PSCustomObject]@{ Name = 'LLAMA_INDEX_API_KEY'; Description = 'LlamaIndex APIキー'; IsMasked = $true; Scope = 'User' },
    
    # OpenRouter
    [PSCustomObject]@{ Name = 'OPENROUTER_API_KEY'; Description = 'OpenRouter APIキー'; IsMasked = $true; Scope = 'User' },
    # [PSCustomObject]@{ Name = 'OPENROUTER_BASE_URL'; Description = 'OpenRouter APIのベースURL'; IsMasked = $false; Scope = 'User' },
    # [PSCustomObject]@{ Name = 'OPENROUTER_SITE_URL'; Description = 'OpenRouter サイトURL（任意）'; IsMasked = $false; Scope = 'User' },
    # [PSCustomObject]@{ Name = 'OPENROUTER_APP_NAME'; Description = 'OpenRouter アプリケーション名（任意）'; IsMasked = $false; Scope = 'User' },
    
    # GitHub
    [PSCustomObject]@{ Name = 'GITHUB_TOKEN'; Description = 'GitHub Personal Access Token'; IsMasked = $true; Scope = 'User' },
    
    # Context7
    [PSCustomObject]@{ Name = 'CONTEXT7_API_KEY'; Description = 'Context7 APIキー'; IsMasked = $true; Scope = 'User' }
)
#endregion

#region 関数定義

function Get-UserEnvironmentVariable {
    param(
        [Parameter(Mandatory)]
        [string]$Name
    )
    [System.Environment]::GetEnvironmentVariable($Name, [System.EnvironmentVariableTarget]::User)
}

function Set-UserEnvironmentVariable {
    param(
        [Parameter(Mandatory)]
        [string]$Name,
        [AllowEmptyString()]
        [string]$Value
    )
    
    try {
        if ([string]::IsNullOrEmpty($Value)) {
            # 空の場合は環境変数を削除
            [System.Environment]::SetEnvironmentVariable($Name, $null, [System.EnvironmentVariableTarget]::User)
        }
        else {
            [System.Environment]::SetEnvironmentVariable($Name, $Value, [System.EnvironmentVariableTarget]::User)
        }
        return $true
    }
    catch {
        Write-Error "環境変数 '$Name' の設定に失敗しました: $_"
        return $false
    }
}

function Initialize-EnvDataGrid {
    <#
    .SYNOPSIS
        環境変数テーブル定義を読み込み、DataGrid用のコレクションを作成
    #>
    $collection = New-Object System.Collections.ObjectModel.ObservableCollection[PSObject]
    
    foreach ($def in $script:EnvVariableDefinitions) {
        $currentValue = Get-UserEnvironmentVariable -Name $def.Name
        
        # マスク対象の場合は表示用に変換
        $displayValue = if ($def.IsMasked -and -not [string]::IsNullOrEmpty($currentValue)) {
            '********'
        }
        else {
            $currentValue
        }
        
        $item = [PSCustomObject]@{
            Name          = $def.Name
            DisplayValue  = $displayValue
            ActualValue   = $currentValue     # 内部的に実際の値を保持
            OriginalValue = $currentValue     # 変更検知用
            Description   = $def.Description
            IsMasked      = $def.IsMasked
            Scope         = $def.Scope
            IsModified    = $false
        }
        
        $collection.Add($item)
    }
    
    return $collection
}

#endregion

#region XAML定義
$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="環境変数エディタ - Windows 11" 
        Height="600" Width="900"
        WindowStartupLocation="CenterScreen"
        ResizeMode="CanResize">
    <Window.Resources>
        <Style TargetType="Button">
            <Setter Property="Margin" Value="5"/>
            <Setter Property="Padding" Value="15,5"/>
            <Setter Property="MinWidth" Value="100"/>
        </Style>
        <Style TargetType="DataGrid">
            <Setter Property="AutoGenerateColumns" Value="False"/>
            <Setter Property="CanUserAddRows" Value="False"/>
            <Setter Property="CanUserDeleteRows" Value="False"/>
            <Setter Property="SelectionMode" Value="Single"/>
            <Setter Property="AlternatingRowBackground" Value="#F5F5F5"/>
            <Setter Property="GridLinesVisibility" Value="Horizontal"/>
            <Setter Property="HeadersVisibility" Value="Column"/>
        </Style>
    </Window.Resources>
    
    <Grid Margin="10">
        <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="*"/>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/>
        </Grid.RowDefinitions>
        
        <!-- ヘッダー -->
        <TextBlock Grid.Row="0" 
                   Text="ユーザー環境変数の管理" 
                   FontSize="18" 
                   FontWeight="Bold"
                   Margin="0,0,0,10"/>
        
        <!-- マスク表示切り替え -->
        <CheckBox Grid.Row="1"
                  Name="ShowAllCheckBox"
                  Content="マスク表示を解除してすべての値を表示する"
                  Margin="0,0,0,10"/>
        
        <!-- DataGrid -->
        <DataGrid Grid.Row="2" 
                  Name="EnvDataGrid"
                  Margin="0,5"
                  IsReadOnly="False">
            <DataGrid.Columns>
                <DataGridTextColumn Header="環境変数名" 
                                    Binding="{Binding Name}" 
                                    Width="250"
                                    IsReadOnly="True"/>
                <DataGridTextColumn Header="値" 
                                    Binding="{Binding DisplayValue, Mode=TwoWay, UpdateSourceTrigger=PropertyChanged}" 
                                    Width="*"/>
                <DataGridTextColumn Header="説明" 
                                    Binding="{Binding Description}" 
                                    Width="300"
                                    IsReadOnly="True"/>
            </DataGrid.Columns>
        </DataGrid>
        
        <!-- 注意事項 -->
        <TextBlock Grid.Row="3"
                   Margin="0,10,0,5"
                   TextWrapping="Wrap"
                   Foreground="#666666">
            <Run Text="※ マスク表示項目 (********) は編集時に新しい値を入力してください。"/>
            <LineBreak/>
            <Run Text="※ 保存後、一部のアプリケーションでは再起動が必要です。"/>
        </TextBlock>
        
        <!-- ボタン群 -->
        <StackPanel Grid.Row="4" 
                    Orientation="Horizontal" 
                    HorizontalAlignment="Right"
                    Margin="0,10,0,0">
            <Button Name="SaveButton" Content="保存" IsDefault="True"/>
            <Button Name="CancelButton" Content="キャンセル"/>
            <Button Name="CloseButton" Content="閉じる" IsCancel="True"/>
        </StackPanel>
    </Grid>
</Window>
"@
#endregion

#region メイン処理

try {
    # XAML読み込み
    $reader = [System.Xml.XmlReader]::Create([System.IO.StringReader]::new($xaml))
    $window = [Windows.Markup.XamlReader]::Load($reader)
    $reader.Close()
    
    # コントロール取得
    $dataGrid = $window.FindName('EnvDataGrid')
    $showAllCheckBox = $window.FindName('ShowAllCheckBox')
    $saveButton = $window.FindName('SaveButton')
    $cancelButton = $window.FindName('CancelButton')
    $closeButton = $window.FindName('CloseButton')
    
    # データ初期化
    $script:EnvCollection = Initialize-EnvDataGrid
    $dataGrid.ItemsSource = $script:EnvCollection
    
    # マスク表示切り替えのイベントハンドラ
    $showAllCheckBox.Add_Checked({
            foreach ($item in $script:EnvCollection) {
                if ($item.IsMasked -and -not [string]::IsNullOrEmpty($item.ActualValue)) {
                    $item.DisplayValue = $item.ActualValue
                }
            }
            $dataGrid.Items.Refresh()
        })
    
    $showAllCheckBox.Add_Unchecked({
            foreach ($item in $script:EnvCollection) {
                if ($item.IsMasked -and -not [string]::IsNullOrEmpty($item.ActualValue)) {
                    $item.DisplayValue = '********'
                }
            }
            $dataGrid.Items.Refresh()
        })
    
    # イベントハンドラ: DataGrid セル編集開始時
    $dataGrid.Add_BeginningEdit({
            param($sender, $e)
        
            $item = $e.Row.Item
            if ($item.IsMasked) {
                # マスク対象項目の編集開始時は、空欄にして新しい値を入力させる
                $item.DisplayValue = ''
            }
        })
    
    # イベントハンドラ: DataGrid セル編集終了時
    $dataGrid.Add_CellEditEnding({
            param($sender, $e)
        
            if ($e.EditAction -eq 'Commit') {
                $item = $e.Row.Item
                $newValue = $item.DisplayValue
            
                # マスク項目かつ空欄の場合は元の値を保持
                if ($item.IsMasked -and [string]::IsNullOrEmpty($newValue)) {
                    $item.DisplayValue = '********'
                }
                else {
                    # 実際の値を更新
                    if ($item.IsMasked) {
                        $item.ActualValue = $newValue
                    }
                    else {
                        $item.ActualValue = $newValue
                    }
                
                    # 変更フラグ
                    $item.IsModified = ($item.ActualValue -ne $item.OriginalValue)
                }
            }
        })
    
    # イベントハンドラ: 保存ボタン
    $saveButton.Add_Click({
            $modifiedItems = $script:EnvCollection | Where-Object { $_.IsModified }
        
            if ($modifiedItems.Count -eq 0) {
                [System.Windows.MessageBox]::Show(
                    '変更がありません。',
                    '情報',
                    [System.Windows.MessageBoxButton]::OK,
                    [System.Windows.MessageBoxImage]::Information
                )
                return
            }
        
            # 確認ダイアログ
            $result = [System.Windows.MessageBox]::Show(
                "$($modifiedItems.Count) 件の環境変数を保存しますか？",
                '確認',
                [System.Windows.MessageBoxButton]::YesNo,
                [System.Windows.MessageBoxImage]::Question
            )
        
            if ($result -eq [System.Windows.MessageBoxResult]::Yes) {
                $successCount = 0
                $errorList = @()
            
                foreach ($item in $modifiedItems) {
                    $success = Set-UserEnvironmentVariable -Name $item.Name -Value $item.ActualValue
                
                    if ($success) {
                        $successCount++
                        $item.OriginalValue = $item.ActualValue
                        $item.IsModified = $false
                    
                        # マスク項目の場合は表示を更新
                        if ($item.IsMasked -and -not [string]::IsNullOrEmpty($item.ActualValue)) {
                            $item.DisplayValue = '********'
                        }
                    }
                    else {
                        $errorList += $item.Name
                    }
                }
            
                if ($errorList.Count -eq 0) {
                    [System.Windows.MessageBox]::Show(
                        "$successCount 件の環境変数を保存しました。",
                        '成功',
                        [System.Windows.MessageBoxButton]::OK,
                        [System.Windows.MessageBoxImage]::Information
                    )
                }
                else {
                    [System.Windows.MessageBox]::Show(
                        "一部の環境変数の保存に失敗しました:`n$($errorList -join ', ')",
                        'エラー',
                        [System.Windows.MessageBoxButton]::OK,
                        [System.Windows.MessageBoxImage]::Error
                    )
                }
            
                # DataGridを更新
                $dataGrid.Items.Refresh()
            }
        })
    
    # イベントハンドラ: キャンセルボタン
    $cancelButton.Add_Click({
            # 変更されている項目があるか確認
            $hasModified = $script:EnvCollection | Where-Object { $_.IsModified }
        
            if ($hasModified) {
                $result = [System.Windows.MessageBox]::Show(
                    '変更を破棄してもよろしいですか？',
                    '確認',
                    [System.Windows.MessageBoxButton]::YesNo,
                    [System.Windows.MessageBoxImage]::Question
                )
            
                if ($result -eq [System.Windows.MessageBoxResult]::Yes) {
                    # ウィンドウを閉じる
                    $window.Close()
                }
            }
            else {
                # 変更がない場合はそのまま閉じる
                $window.Close()
            }
        })
    
    # イベントハンドラ: 閉じるボタン
    $closeButton.Add_Click({
            # 未保存の変更があるか確認
            $hasModified = $script:EnvCollection | Where-Object { $_.IsModified }
        
            if ($hasModified) {
                $result = [System.Windows.MessageBox]::Show(
                    '未保存の変更があります。保存せずに閉じますか？',
                    '確認',
                    [System.Windows.MessageBoxButton]::YesNo,
                    [System.Windows.MessageBoxImage]::Warning
                )
            
                if ($result -eq [System.Windows.MessageBoxResult]::Yes) {
                    $window.Close()
                }
            }
            else {
                $window.Close()
            }
        })
    
    # ウィンドウ表示
    [void]$window.ShowDialog()
}
catch {
    Write-Error "エラーが発生しました: $_"
    [System.Windows.MessageBox]::Show(
        "エラーが発生しました:`n$_",
        'エラー',
        [System.Windows.MessageBoxButton]::OK,
        [System.Windows.MessageBoxImage]::Error
    )
}

#endregion
