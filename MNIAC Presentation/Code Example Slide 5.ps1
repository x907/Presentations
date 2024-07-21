<#
.SYNOPSIS
Creates a new Azure AD user with a license using Microsoft Graph.

.DESCRIPTION
This function creates a new Azure AD user with a specified display name, user principal name, mail nickname, password, license SKU part number, and Azure Key Vault name. It retrieves the necessary credentials from the Azure Key Vault, authenticates with Microsoft Graph, creates a new user, assigns the specified license, and outputs the details of the newly created user.

.PARAMETER DisplayName
The display name of the new user.

.PARAMETER UserPrincipalName
The user principal name (UPN) of the new user.

.PARAMETER MailNickName
The mail nickname of the new user.

.PARAMETER Password
The password for the new user.

.PARAMETER LicenseSkuPartNumber
The SKU part number of the license to assign to the new user.

.PARAMETER KeyVaultName
The name of the Azure Key Vault where the credentials are stored.

.EXAMPLE
New-AzureADUserWithLicenseUsingGraph -DisplayName "New User" -UserPrincipalName "newuser@example.com" -MailNickName "newuser" -Password "InitialPassword123" -LicenseSkuPartNumber "ENTERPRISEPACK" -KeyVaultName "YourKeyVaultName"
#>
function New-AzureADUserWithLicenseUsingGraph {
    param (
        [Parameter(Mandatory=$true)]
        [string]$DisplayName,
        [Parameter(Mandatory=$true)]
        [string]$UserPrincipalName,
        [Parameter(Mandatory=$true)]
        [string]$MailNickName,
        [Parameter(Mandatory=$true)]
        [string]$Password,
        [Parameter(Mandatory=$true)]
        [string]$LicenseSkuPartNumber,
        [Parameter(Mandatory=$true)]
        [string]$KeyVaultName
    )

    # Retrieve credentials from Azure Key Vault
    $clientId = (Get-AzKeyVaultSecret -VaultName $KeyVaultName -Name "ClientId").SecretValueText
    $tenantId = (Get-AzKeyVaultSecret -VaultName $KeyVaultName -Name "TenantId").SecretValueText
    $clientSecret = (Get-AzKeyVaultSecret -VaultName $KeyVaultName -Name "ClientSecret").SecretValueText

    # Authenticate with Microsoft Graph
    $credential = New-Object Microsoft.Graph.PowerShell.Authentication.Models.GraphTokenCredential -ArgumentList $clientId, $clientSecret, $tenantId
    Connect-MgGraph -Credential $credential -Scopes "https://graph.microsoft.com/.default" -TenantId $tenantId

    # Create new user
    $userPasswordProfile = @{
        Password = $Password
        ForceChangePasswordNextSignIn = $true
    }
    $newUser = New-MgUser -DisplayName $DisplayName -UserPrincipalName $UserPrincipalName -MailNickname $MailNickName -PasswordProfile $userPasswordProfile -AccountEnabled $true

    # Assign license
    $license = Get-MgSubscribedSku | Where-Object -Property SkuPartNumber -EQ $LicenseSkuPartNumber
    if ($license -eq $null) {
        Write-Error "License SKU not found."
        return
    }
    $licenseAssignment = @{
        "addLicenses" = @(
            @{
                "disabledPlans" = @();
                "skuId" = $license.SkuId
            }
        )
        "removeLicenses" = @()
    }
    Invoke-MgGraphRequest -Method POST -Uri "https://graph.microsoft.com/v1.0/users/$($newUser.Id)/assignLicense" -Body ($licenseAssignment | ConvertTo-Json)

    # Output the newly created user details
    Get-MgUser -UserId $newUser.Id | Format-List DisplayName, UserPrincipalName, Id
}
