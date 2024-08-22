# Get all users
$users = Get-AzureADUser -All $true

# Filter users with PasswordPolicies set to DisablePasswordExpiration
$filteredUsers = $users | Where-Object { $_.PasswordPolicies -eq "DisablePasswordExpiration" }

# Display the filtered users
$filteredUsers
