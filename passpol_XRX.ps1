# Import the Active Directory and Azure AD Modules
Import-Module ActiveDirectory
Import-Module AzureAD

# Connect to Azure AD for querying Azure/Entra ID password policies
Connect-AzureAD

# Define the OU for searching AD users
$ou = "OU=Retail Users GPP,OU=Users,OU=Managed Users & Computers,DC=corp,DC=gianteagle,DC=com"

# Filter all users in the OU where samAccountName starts with 's' and ends with 'xrx'
$users = Get-ADUser -Filter {(sAMAccountName -like 's*xrx')} -SearchBase $ou -Property SamAccountName,ObjectGUID

# Create an array to store the results
$results = @()

# Loop through each user and get their AD and Azure/Entra ID password policy
foreach ($user in $users) {
    $samAccountName = $user.SamAccountName
    $objectGUID = $user.ObjectGUID

    # Get AD Password Policy
    $adPasswordPolicy = Get-ADUserResultantPasswordPolicy -Identity $user | Select-Object -ExpandProperty Name

    # Get Azure/Entra ID Password Policy
    $azurePasswordPolicies = ""
    try {
        $azureUser = Get-AzureADUser -ObjectId $objectGUID
        if ($azureUser) {
            $azurePasswordPolicies = $azureUser.PasswordPolicies
        }
    } catch {
        # Handle case where user is not found in Azure AD
        $azurePasswordPolicies = "Not found in Azure AD"
    }

    # Add the result to the array
    $results += [PSCustomObject]@{
        SamAccountName = $samAccountName
        ADPasswordPolicy = $adPasswordPolicy
        AzurePasswordPolicy = $azurePasswordPolicies
    }
}

# Export the results to a CSV file
$csvPath = "C:\temp\s_xrx_accounts_audit.csv"
$results | Export-Csv -Path $csvPath -NoTypeInformation

# Output where the CSV was saved
Write-Host "Audit complete. CSV file saved to: $csvPath"
