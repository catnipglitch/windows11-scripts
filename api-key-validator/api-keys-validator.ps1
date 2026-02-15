# ============================================================
#  API キー検証 GUI
#  対応: OpenAI / Anthropic (Claude) / Google Gemini / OpenRouter
#  実行環境: PowerShell 5.1+ / pwsh 7+
#  追加インストール不要（Windows 標準の System.Windows.Forms を使用）
# ============================================================

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# ─────────────────────────────────────────────
#  Color Definitions
# ─────────────────────────────────────────────
$clrBg = [System.Drawing.Color]::FromArgb(245, 245, 250)
$clrPanel = [System.Drawing.Color]::White
$clrAccent = [System.Drawing.Color]::FromArgb(99, 102, 241)   # indigo
$clrSuccess = [System.Drawing.Color]::FromArgb(34, 197, 94)
$clrError = [System.Drawing.Color]::FromArgb(239, 68, 68)
$clrWarn = [System.Drawing.Color]::FromArgb(234, 179, 8)
$clrTextDark = [System.Drawing.Color]::FromArgb(30, 30, 40)
$clrTextGray = [System.Drawing.Color]::FromArgb(120, 120, 140)
$clrBorder = [System.Drawing.Color]::FromArgb(220, 220, 235)

# ─────────────────────────────────────────────
#  API Validation Functions
# ─────────────────────────────────────────────

function Test-OpenAI {
    param([string]$Key)
    try {
        $headers = @{ "Authorization" = "Bearer $Key" }
        $resp = Invoke-WebRequest -Uri "https://api.openai.com/v1/models" `
            -Headers $headers -UseBasicParsing -TimeoutSec 10
        if ($resp.StatusCode -eq 200) {
            $json = $resp.Content | ConvertFrom-Json
            $count = ($json.data | Measure-Object).Count
            return @{ OK = $true; Msg = "✔ 有効 (モデル数: $count)" }
        }
    }
    catch {
        $code = $_.Exception.Response.StatusCode.value__
        if ($code -eq 401) { return @{ OK = $false; Msg = "✘ 無効なAPIキー (401 Unauthorized)" } }
        if ($code -eq 429) { return @{ OK = $true; Msg = "⚠ キーは有効だがレート制限中 (429)" } }
        return @{ OK = $false; Msg = "✘ エラー: $($_.Exception.Message)" }
    }
    return @{ OK = $false; Msg = "✘ 不明なエラー" }
}

function Test-Anthropic {
    param([string]$Key)
    try {
        $headers = @{
            "x-api-key"         = $Key
            "anthropic-version" = "2023-06-01"
        }
        $resp = Invoke-WebRequest -Uri "https://api.anthropic.com/v1/models" `
            -Headers $headers -UseBasicParsing -TimeoutSec 10
        if ($resp.StatusCode -eq 200) {
            $json = $resp.Content | ConvertFrom-Json
            $count = ($json.data | Measure-Object).Count
            return @{ OK = $true; Msg = "Valid (Models: $count)" }
        }
    }
    catch {
        $code = $_.Exception.Response.StatusCode.value__
        if ($code -eq 401) { return @{ OK = $false; Msg = "Invalid API Key (401 Unauthorized)" } }
        if ($code -eq 429) { return @{ OK = $true; Msg = "Valid but Rate Limited (429)" } }
        return @{ OK = $false; Msg = "Error: $($_.Exception.Message)" }
    }
    return @{ OK = $false; Msg = "Unknown Error" }
}

function Test-Gemini {
    param([string]$Key)
    try {
        $url = "https://generativelanguage.googleapis.com/v1beta/models?key=$Key"
        $resp = Invoke-WebRequest -Uri $url -UseBasicParsing -TimeoutSec 10
        if ($resp.StatusCode -eq 200) {
            $json = $resp.Content | ConvertFrom-Json
            $count = ($json.models | Measure-Object).Count
            return @{ OK = $true; Msg = "Valid (Models: $count)" }
        }
    }
    catch {
        $code = $_.Exception.Response.StatusCode.value__
        if ($code -eq 400) { return @{ OK = $false; Msg = "Invalid API Key (400 Bad Request)" } }
        if ($code -eq 403) { return @{ OK = $false; Msg = "No Permission (403 Forbidden)" } }
        if ($code -eq 429) { return @{ OK = $true; Msg = "Valid but Rate Limited (429)" } }
        return @{ OK = $false; Msg = "Error: $($_.Exception.Message)" }
    }
    return @{ OK = $false; Msg = "Unknown Error" }
}

function Test-OpenRouter {
    param([string]$Key)
    try {
        $headers = @{ "Authorization" = "Bearer $Key" }
        $resp = Invoke-WebRequest -Uri "https://openrouter.ai/api/v1/models" `
            -Headers $headers -UseBasicParsing -TimeoutSec 10
        if ($resp.StatusCode -eq 200) {
            $json = $resp.Content | ConvertFrom-Json
            $count = ($json.data | Measure-Object).Count
            return @{ OK = $true; Msg = "Valid (Models: $count)" }
        }
    }
    catch {
        $code = $_.Exception.Response.StatusCode.value__
        if ($code -eq 401) { return @{ OK = $false; Msg = "Invalid API Key (401 Unauthorized)" } }
        if ($code -eq 403) { return @{ OK = $false; Msg = "No Permission (403 Forbidden)" } }
        if ($code -eq 429) { return @{ OK = $true; Msg = "Valid but Rate Limited (429)" } }
        return @{ OK = $false; Msg = "Error: $($_.Exception.Message)" }
    }
    return @{ OK = $false; Msg = "Unknown Error" }
}

# ─────────────────────────────────────────────
#  UI Helper Functions
# ─────────────────────────────────────────────

function New-Label {
    param($Text, $X, $Y, $W = 300, $H = 20, $Bold = $false, $Color = $null)
    $lbl = New-Object System.Windows.Forms.Label
    $lbl.Text = $Text
    $lbl.Location = [System.Drawing.Point]::new($X, $Y)
    $lbl.Size = [System.Drawing.Size]::new($W, $H)
    $lbl.ForeColor = if ($Color) { $Color } else { $clrTextDark }
    $lbl.Font = if ($Bold) {
        New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
    }
    else {
        New-Object System.Drawing.Font("Segoe UI", 9)
    }
    return $lbl
}

function New-TextBox {
    param($X, $Y, $W = 340, $Password = $false)
    $tb = New-Object System.Windows.Forms.TextBox
    $tb.Location = [System.Drawing.Point]::new($X, $Y)
    $tb.Size = [System.Drawing.Size]::new($W, 26)
    $tb.Font = New-Object System.Drawing.Font("Consolas", 9)
    $tb.BorderStyle = [System.Windows.Forms.BorderStyle]::FixedSingle
    $tb.BackColor = [System.Drawing.Color]::White
    if ($Password) { $tb.PasswordChar = '●' }
    return $tb
}

function New-StatusLabel {
    param($X, $Y, $W = 340)
    $lbl = New-Object System.Windows.Forms.Label
    $lbl.Location = [System.Drawing.Point]::new($X, $Y)
    $lbl.Size = [System.Drawing.Size]::new($W, 20)
    $lbl.Text = "Not checked"
    $lbl.ForeColor = $clrTextGray
    $lbl.Font = New-Object System.Drawing.Font("Segoe UI", 8.5)
    return $lbl
}

# ─────────────────────────────────────────────
#  Main Form
# ─────────────────────────────────────────────

$form = New-Object System.Windows.Forms.Form
$form.Text = "API Key Validator"
$form.Size = [System.Drawing.Size]::new(1280, 1280)
$form.StartPosition = "CenterScreen"
$form.BackColor = $clrBg
$form.FormBorderStyle = "FixedSingle"
$form.MaximizeBox = $false
$form.Font = New-Object System.Drawing.Font("Segoe UI", 9)

# ── Title Bar ──
$pnlTitle = New-Object System.Windows.Forms.Panel
$pnlTitle.Location = [System.Drawing.Point]::new(0, 0)
$pnlTitle.Size = [System.Drawing.Size]::new(1280, 52)
$pnlTitle.BackColor = $clrAccent
$form.Controls.Add($pnlTitle)

$lblTitle = New-Object System.Windows.Forms.Label
$lblTitle.Text = "API Key Validator"
$lblTitle.Location = [System.Drawing.Point]::new(16, 12)
$lblTitle.Size = [System.Drawing.Size]::new(1200, 28)
$lblTitle.ForeColor = [System.Drawing.Color]::White
$lblTitle.Font = New-Object System.Drawing.Font("Segoe UI", 13, [System.Drawing.FontStyle]::Bold)
$pnlTitle.Controls.Add($lblTitle)

# ── Main Panel ──
$pnlMain = New-Object System.Windows.Forms.Panel
$pnlMain.Location = [System.Drawing.Point]::new(14, 62)
$pnlMain.Size = [System.Drawing.Size]::new(1246, 1160)
$pnlMain.BackColor = $clrPanel
$pnlMain.BorderStyle = [System.Windows.Forms.BorderStyle]::FixedSingle
$pnlMain.AutoScroll = $false
$form.Controls.Add($pnlMain)

# ─── Platform Configuration ───
$platforms = @(
    @{ Name = "OpenAI"; Hint = "sk-..." }
    @{ Name = "Anthropic"; Hint = "sk-ant-..." }
    @{ Name = "Gemini"; Hint = "AIza..." }
    @{ Name = "OpenRouter"; Hint = "sk-or-..." }
)

$rows = @{}   # Store TextBox and StatusLabel references

$yPos = 14
$platformHeight = 190

foreach ($p in $platforms) {
    # Platform Header
    $lblPlatform = New-Label -Text $p.Name -X 14 -Y $yPos -W 1200 -Bold $true
    $lblPlatform.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
    $pnlMain.Controls.Add($lblPlatform)
    
    $yPos += 28
    
    # Create 3 API key inputs for each platform
    $platformRows = @()
    for ($i = 1; $i -le 3; $i++) {
        $keyY = $yPos + (($i - 1) * 60)
        
        # Key number label (horizontally aligned with textbox)
        $lblNum = New-Label -Text "Key #$i" -X 24 -Y $keyY -W 70 -H 26
        $pnlMain.Controls.Add($lblNum)
        
        # TextBox (on the same line as label)
        $tb = New-TextBox -X 100 -Y $keyY -W 1000 -Password $true
        $tb.PlaceholderText = $p.Hint
        $pnlMain.Controls.Add($tb)
        
        # Show/Hide toggle button (on the same line)
        $btnShow = New-Object System.Windows.Forms.Button
        $btnShow.Text = "Show"
        $btnShow.Location = [System.Drawing.Point]::new(1106, $keyY)
        $btnShow.Size = [System.Drawing.Size]::new(70, 26)
        $btnShow.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
        $btnShow.FlatAppearance.BorderSize = 1
        $btnShow.FlatAppearance.BorderColor = $clrBorder
        $btnShow.BackColor = [System.Drawing.Color]::White
        $btnShow.Cursor = [System.Windows.Forms.Cursors]::Hand
        $btnShow.Font = New-Object System.Drawing.Font("Segoe UI", 7.5)
        $btnShow.Tag = $tb
        $btnShow.Add_Click({
                $t = $this.Tag
                if ($t.PasswordChar -eq [char]9679) {
                    $t.PasswordChar = [char]0
                    $this.Text = "Hide"
                }
                else {
                    $t.PasswordChar = [char]9679
                    $this.Text = "Show"
                }
            })
        $pnlMain.Controls.Add($btnShow)
        
        # Status Label (on the next line below textbox)
        $st = New-StatusLabel -X 100 -Y ($keyY + 30) -W 1076
        $pnlMain.Controls.Add($st)
        
        $platformRows += @{ TB = $tb; ST = $st }
    }
    
    $rows[$p.Name] = $platformRows
    $yPos += 182
    
    # Separator (except for last platform)
    if ($p -ne $platforms[-1]) {
        $sep = New-Object System.Windows.Forms.Panel
        $sep.Location = [System.Drawing.Point]::new(14, $yPos - 6)
        $sep.Size = [System.Drawing.Size]::new(1216, 2)
        $sep.BackColor = $clrBorder
        $pnlMain.Controls.Add($sep)
        $yPos += 8
    }
}

# ── Button Row ──
$btnCheck = New-Object System.Windows.Forms.Button
$btnCheck.Text = "Check All"
$btnCheck.Location = [System.Drawing.Point]::new(14, 1228)
$btnCheck.Size = [System.Drawing.Size]::new(200, 36)
$btnCheck.BackColor = $clrAccent
$btnCheck.ForeColor = [System.Drawing.Color]::White
$btnCheck.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$btnCheck.FlatAppearance.BorderSize = 0
$btnCheck.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
$btnCheck.Cursor = [System.Windows.Forms.Cursors]::Hand
$form.Controls.Add($btnCheck)

$btnClear = New-Object System.Windows.Forms.Button
$btnClear.Text = "Clear All"
$btnClear.Location = [System.Drawing.Point]::new(224, 1228)
$btnClear.Size = [System.Drawing.Size]::new(120, 36)
$btnClear.BackColor = $clrBorder
$btnClear.ForeColor = $clrTextDark
$btnClear.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$btnClear.FlatAppearance.BorderSize = 0
$btnClear.Font = New-Object System.Drawing.Font("Segoe UI", 9)
$btnClear.Cursor = [System.Windows.Forms.Cursors]::Hand
$form.Controls.Add($btnClear)

# ── Status Bar ──
$lblStatus = New-Object System.Windows.Forms.Label
$lblStatus.Text = "Enter API keys and click 'Check All'"
$lblStatus.Location = [System.Drawing.Point]::new(0, 1260)
$lblStatus.Size = [System.Drawing.Size]::new(1280, 20)
$lblStatus.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter
$lblStatus.BackColor = $clrAccent
$lblStatus.ForeColor = [System.Drawing.Color]::White
$lblStatus.Font = New-Object System.Drawing.Font("Segoe UI", 8)
$form.Controls.Add($lblStatus)

# ─────────────────────────────────────────────
#  Check Button Handler
# ─────────────────────────────────────────────

$btnCheck.Add_Click({
        $btnCheck.Enabled = $false
        $btnCheck.Text = "Checking..."
        $lblStatus.Text = "Checking API keys, please wait..."
        $form.Refresh()

        $checkMap = @{
            "OpenAI"     = { param($key) Test-OpenAI -Key $key }
            "Anthropic"  = { param($key) Test-Anthropic -Key $key }
            "Gemini"     = { param($key) Test-Gemini -Key $key }
            "OpenRouter" = { param($key) Test-OpenRouter -Key $key }
        }

        $okCount = 0
        $skipCount = 0
        $totalKeys = 0

        foreach ($name in $checkMap.Keys) {
            $platformRows = $rows[$name]
            
            for ($i = 0; $i -lt $platformRows.Count; $i++) {
                $tb = $platformRows[$i].TB
                $st = $platformRows[$i].ST
                $totalKeys++

                if ([string]::IsNullOrWhiteSpace($tb.Text)) {
                    $st.Text = "Skipped (empty)"
                    $st.ForeColor = $clrTextGray
                    $skipCount++
                    continue
                }

                $st.Text = "Checking..."
                $st.ForeColor = $clrWarn
                $form.Refresh()

                $result = & $checkMap[$name] $tb.Text

                $st.Text = $result.Msg
                if ($result.OK) {
                    $st.ForeColor = $clrSuccess
                    $okCount++
                }
                else {
                    $st.ForeColor = $clrError
                }
                $form.Refresh()
            }
        }

        $checked = $totalKeys - $skipCount
        $lblStatus.Text = "Done: $checked checked / $okCount valid"
        $btnCheck.Text = "Check All"
        $btnCheck.Enabled = $true
    })

# ─────────────────────────────────────────────
#  Clear Button Handler
# ─────────────────────────────────────────────

$btnClear.Add_Click({
        foreach ($name in $rows.Keys) {
            $platformRows = $rows[$name]
            for ($i = 0; $i -lt $platformRows.Count; $i++) {
                $platformRows[$i].TB.Text = ""
                $platformRows[$i].ST.Text = "Not checked"
                $platformRows[$i].ST.ForeColor = $clrTextGray
            }
        }
        $lblStatus.Text = "Enter API keys and click 'Check All'"
    })

# ─────────────────────────────────────────────
#  Launch
# ─────────────────────────────────────────────

[System.Windows.Forms.Application]::EnableVisualStyles()
$form.Add_Shown({ $form.Activate() })
[void]$form.ShowDialog()
