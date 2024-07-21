<#
.SYNOPSIS
Enables Multi-Factor Authentication (MFA) for an Azure AD user.

.DESCRIPTION
The Enable-AzureADMFA function connects to Azure AD and enables MFA for the specified user. If MFA is already enabled for the user, it returns without making any changes.

.PARAMETER userId
The Object ID or User Principal Name (UPN) of the user for whom MFA needs to be enabled.

.EXAMPLE
Enable-AzureADMFA -userId "user1@contoso.com"
Connects to Azure AD and enables MFA for the user with the specified UPN.

.NOTES
Author: Your Name
Date: Today's Date
#>

function Enable-AzureADMFA {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [string]$userId
    )

    try {
        Write-Output "Connecting to Azure AD..."
        Connect-AzureAD | Out-Null

        $user = Get-AzureADUser -ObjectId $userId -ErrorAction Stop
        if ($user.StrongAuthenticationRequirements.State -eq "Enabled") {
            Write-Output "MFA is already enabled for user: $userId"
            return
        }

        $strongAuthenticationRequirement = @{
            "State"="Enabled"; 
            "RememberDevicesNotIssuedBefore"= (Get-Date)
        }
        Set-AzureADUser -ObjectId $userId -StrongAuthenticationRequirements @($strongAuthenticationRequirement) -ErrorAction Stop

        Write-Output "MFA has been enabled for user: $userId"
    } catch {
        Write-Error "An error occurred: $_"
    }
}

# Example usage: Enable-AzureADMFA -userId "user1@contoso.com"