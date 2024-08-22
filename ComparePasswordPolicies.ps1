# Import the AzureAD and ActiveDirectory modules
#Import-Module AzureAD
Import-Module ActiveDirectory

# Connect to Azure AD
#Connect-AzureAD

# Get all Azure AD users
$users = Get-AzureADUser -All $true

# Filter users with PasswordPolicies set to DisablePasswordExpiration
$filteredUsers = $users | Where-Object { $_.PasswordPolicies -eq "DisablePasswordExpiration" }

# Create a list to store the report data
$report = @()

foreach ($user in $filteredUsers) {
    # Get the UPN of the user
    $upn = $user.UserPrincipalName

    # Check if the user exists in on-premises AD by UPN
    $adUser = Get-ADUser -Filter { UserPrincipalName -eq $upn } -Properties PasswordNeverExpires

    # If the user doesn't exist in on-premises AD, try locating by Display Name
    if (!$adUser) {
        $displayName = $user.DisplayName
        $adUser = Get-ADUser -Filter { DisplayName -eq $displayName } -Properties PasswordNeverExpires
    }

    # Create a custom object for the report
    $reportItem = [pscustomobject]@{
        DisplayName          = $user.DisplayName
        UserPrincipalName    = $user.UserPrincipalName
        PasswordPolicies     = $user.PasswordPolicies
        PasswordNeverExpires = $null
    }

    # If the user exists in on-premises AD, add the PasswordNeverExpires status
    if ($adUser) {
        $reportItem.PasswordNeverExpires = $adUser.PasswordNeverExpires
    } else {
        $reportItem.PasswordNeverExpires = 'Not found in on-premises AD'
    }

    # Add the report item to the report list
    $report += $reportItem
}

# Display the report
$report | Format-Table -AutoSize

# Optionally, export the report to a CSV file
$report | Export-Csv -Path C:\temp\PasswordPolicyReport.csv -NoTypeInformation
