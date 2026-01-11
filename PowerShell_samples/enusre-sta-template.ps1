# STAオプションを矯正するテンプレ。


# STAオプションが付与されていなければ、付与して起動する
param([switch]$S)
if ($Host.Runspace.ApartmentState -ne 'STA' -and -not $S) {
    Start-Process pwsh "-STA -File `"$PSCommandPath`" -S"
    exit
}
