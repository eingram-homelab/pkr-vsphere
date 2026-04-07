# CICD - GitHub Action
# Script to delete existing VM template and replace with new built template

param (
    [string]$oldTemplateName,
    [string]$newTemplateName
)

function Get-VaultSecret {
    param (
        $vaultAddress,
        $secretPath,
        $secret,
        $vaultToken
    )

    # Construct the API request
    $uri = "$vaultAddress/v1/$secretPath"
    $headers = @{
        "X-Vault-Token" = $vaultToken
    }

    try {
        # Retrieve the secret
        $response = Invoke-RestMethod -Method GET -Uri $uri -Headers $headers
        # Extract the secret data
        $secretData = $response.data.$secret

        # Return the secret value
        return $secretData

    } catch {
        # Handle errors
        Write-Error "Error retrieving secret: $($_.Exception.Message)"
    }
}

# Start Script
Install-Module VMware.PowerCLI -Scope CurrentUser -Force -AllowClobber
Set-PowerCLIConfiguration -InvalidCertificateAction Ignore -Confirm:$false
$vaultToken = $env:VAULT_TOKEN
$vaultAddress = "http://vault.local.lan:8200"
$username = Get-VaultSecret $vaultAddress "secret/vsphere/vcsa" "vsphere_username" $vaultToken
$password = Get-VaultSecret $vaultAddress "secret/vsphere/vcsa" "vsphere_password" $vaultToken 
$cred = New-Object System.Management.Automation.PSCredential($username, (ConvertTo-SecureString $password -AsPlainText -Force))

Try {
    Connect-VIServer -Server vcsa-1.local.lan -Credential $cred
} Catch {
    Write-Error "Failed to connect to vCenter: $($_.Exception.Message)"
    Exit 1
}
# Remove the old template
If (!(Get-Template -Name $oldTemplateName -ErrorAction SilentlyContinue)) {
    Write-Host "Old template $oldTemplateName does not exist, skipping removal."
} else {
    Write-Host "Old template $oldTemplateName exists, removing it."
    Try {
        Remove-Template -Template $oldTemplateName -DeletePermanently -Confirm:$false
    } Catch {
        Write-Error "Failed to remove old template: $($_.Exception.Message)"
        Disconnect-VIServer -Server vcsa-1.local.lan -Confirm:$false
        Exit 1
    }
}

Write-Host "Renaming new template: $newTemplateName to $oldTemplateName"
Try {
    Set-Template -Template $newTemplateName -Name $oldTemplateName -Confirm:$false
} Catch {
    Write-Error "Failed to rename template: $($_.Exception.Message)"
    Disconnect-VIServer -Server vcsa-1.local.lan -Confirm:$false
    Exit 1
}

# Disconnect from vCenter
Disconnect-VIServer -Server vcsa-1.local.lan -Confirm:$false