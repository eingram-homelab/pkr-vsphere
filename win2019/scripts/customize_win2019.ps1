$ProgressPreference = "SilentlyContinue"
$ErrorActionPreference = "Stop"

#Start-Transcript C:\customise.txt

try {
    # Set Temp Variable using PowerShell

    $TempFolder = "C:\TEMP";
    New-Item -ItemType Directory -Force -Path $TempFolder;
    [Environment]::SetEnvironmentVariable("TEMP", $TempFolder, [EnvironmentVariableTarget]::Machine);
    [Environment]::SetEnvironmentVariable("TMP", $TempFolder, [EnvironmentVariableTarget]::Machine);
    [Environment]::SetEnvironmentVariable("TEMP", $TempFolder, [EnvironmentVariableTarget]::User);
    [Environment]::SetEnvironmentVariable("TMP", $TempFolder, [EnvironmentVariableTarget]::User);

    # Disable Server Manager from starting up automatically
    Get-ScheduledTask -TaskName ServerManager | Disable-ScheduledTask -Verbose

    # # Disable password expiration for your local admin account.
    # Write-Host "Setting admin account to not expire..."
    # wmic useraccount where "name='administrator'" set PasswordExpires=FALSE

    # Enable RDP
    netsh advfirewall firewall add rule name="Open Port 3389" dir=in action=allow protocol=TCP localport=3389
    reg add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Terminal Server" /v fDenyTSConnections /t REG_DWORD /d 0 /f

    # Set power plan to High Performance.
    Write-Host "Setting power plan to high performance..."
    $p = Get-CimInstance -Name root\cimv2\power -Class win32_PowerPlan -Filter "ElementName = 'High Performance'"      
    powercfg /setactive ([string]$p.InstanceID).Replace("Microsoft:PowerPlan\{","").Replace("}","")

    # # Show file extensions in Windows Explorer.
    # Write-Host "Enabling file extensions in Windows Explorer..."
    # Set-Itemproperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "HideFileExt" -Value 0 -Verbose

    ##### While the step below I had to do previously, this breaks now since an application is now required. For some reason, running it manually works. 
    ##### Regardless, it seems I no longer need to remove AppxPackages in order for sysprep to work. 
    # Remove AppxPackages. Windows store applications breaks sysprep. 
    #Get-AppxPackage | Remove-AppxPackage
}
catch {
    Write-Host
    Write-Host "Something went wrong:" 
    Write-Host ($PSItem.Exception.Message)
    Write-Host

    # Sleep for 60 minutes so you can see the errors before the VM is destroyed by Packer.
    Start-Sleep -Seconds 3600

    Exit 1
}

Start-Sleep -Seconds 10