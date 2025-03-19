# Import the AzureAD module
#Import-Module AzureAD

# Connect to Azure AD
#Connect-AzureAD

# Search for users with specific UPN patterns and exclude 'saccpossrv@gianteagle.com'
$users = Get-AzureADUser -All $true | Where-Object {
    ($_UserPrincipalName -like "s*psh@gianteagle.com" -or
     $_UserPrincipalName -like "s*gso@gianteagle.com" -or
     $_UserPrincipalName -like "s*srv@gianteagle.com") -and
     $_UserPrincipalName -ne "saccpossrv@gianteagle.com"
}

# Display the selected users
$users | Select-Object DisplayName, UserPrincipalName

# Disable password expiration for the selected users
foreach ($user in $results) {
    Set-AzureADUser -ObjectId $user.ObjectId -PasswordPolicies "DisablePasswordExpiration"
}

Write-Host "Password expiration disabled for selected users."
