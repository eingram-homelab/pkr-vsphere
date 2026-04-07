Write-Host "Remove All Unwanted Windows Built-in Store Apps for All New Users in UI..."
Get-AppxPackage -AllUsers | Where-Object {$_.IsFramework -Match 'False' -and $_.NonRemovable -Match 'False' -and $_.Name -NotMatch 'Microsoft.StorePurchaseApp' -and $_.Name -NotMatch 'Microsoft.WindowsStore' -and $_.Name -NotMatch 'Microsoft.MSPaint' -and $_.Name -NotMatch 'Microsoft.Windows.Photos' -and $_.Name -NotMatch 'Microsoft.WindowsCalculator'} | Remove-AppxPackage -ErrorAction SilentlyContinue

Write-Host "Remove All Unwanted Windows Built-in Store Apps for the Current User in UI..."
Get-AppxPackage | Where-Object {$_.IsFramework -Match 'False' -and $_.NonRemovable -Match 'False' -and $_.Name -NotMatch 'Microsoft.StorePurchaseApp' -and $_.Name -NotMatch 'Microsoft.WindowsStore' -and $_.Name -NotMatch 'Microsoft.MSPaint' -and $_.Name -NotMatch 'Microsoft.Windows.Photos' -and $_.Name -NotMatch 'Microsoft.WindowsCalculator'} | Remove-AppxPackage -ErrorAction SilentlyContinue

Write-Host "Remove All Unwanted Windows Built-in Store Apps files from Disk..."
$UWPapps = Get-AppxProvisionedPackage -Online | Where-Object {$_.PackageName -NotMatch 'Microsoft.StorePurchaseApp' -and $_.PackageName -NotMatch 'Microsoft.WindowsStore' -and $_.PackageName -NotMatch 'Microsoft.MSPaint' -and $_.PackageName -NotMatch 'Microsoft.Windows.Photos' -and $_.PackageName -NotMatch 'Microsoft.WindowsCalculator'}
Foreach ($UWPapp in $UWPapps) {
    Remove-ProvisionedAppxPackage -PackageName $UWPapp.PackageName -Online -ErrorAction SilentlyContinue
}