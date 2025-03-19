# Import Active Directory module
Import-Module ActiveDirectory

# Set the updated search base and filter for SRV accounts
$SearchBase = "OU=Corporate Users,OU=Users,OU=Managed Users & Computers,DC=corp,DC=gianteagle,DC=com"
$Filter = "Name -like '*'"

# Get all SRV accounts with relevant properties
$SRVAccounts = Get-ADUser -Filter $Filter -Properties SamAccountName, UserPrincipalName, LastLogonDate, Enabled

# Initialize an array to hold account details
$AccountDetails = @()

foreach ($Account in $SRVAccounts) {
    # Check for Last Logon Date
    $LastLogonDate = if ($Account.LastLogonDate) {
        $Account.LastLogonDate
    } else {
        "Never Logged In"
    }

    # Add the account details to the array
    $AccountDetails += [PSCustomObject]@{
        SamAccountName    = $Account.SamAccountName
        UserPrincipalName = if ($Account.UserPrincipalName) { $Account.UserPrincipalName } else { "Not Set" }
        LastLogon         = $LastLogonDate
        Enabled           = $Account.Enabled
    }
}

# Ensure the directory exists
$ReportDirectory = "C:\Reports"
if (!(Test-Path -Path $ReportDirectory)) {
    New-Item -ItemType Directory -Path $ReportDirectory
}

# Export the data to a CSV file
$CSVFilePath = Join-Path -Path $ReportDirectory -ChildPath "SRVAccountsReport.csv"
$AccountDetails | Export-Csv -Path $CSVFilePath -NoTypeInformation

# Output to console for immediate review
$AccountDetails | Format-Table -AutoSize

Write-Output "SRV Accounts report has been saved to: $CSVFilePath"