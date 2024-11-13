<##########
### Title: Update Dynamic Group Membership
### Author: Luke Encrapera
### Email: Luke.Encrapera@GiantEagle.com
### Date: 9/24/2021
##########>

<#  USAGE:
    Update $targetedGroups and $filterRule before running 
    Comment out the Set-AzureADMSGroup in the $reportHash loop to report without setting anything
    All output files are saved to C:\Temp\
#>

Import-Module AzureADPreview

# Initialize Variables
$DynamicGroupSet = @()
$targetedGroups = @()
$storeInfo = @{}
$reportHash = @{}
$outputRules = @()
$DateTime = Get-Date -f "yyyy-MM-dd HH-mm" 
$reportLocations = @(
    "C:\Temp\DynamicGroupSet_$DateTime.csv",
    "C:\Temp\reportHash_$DateTime.txt",
    "C:\Temp\reportStores_$DateTime.txt",
    "C:\Temp\reportAdds_$DateTime.txt",
    "C:\Temp\whatIsSet_$DateTime.txt"
)

# Define locations to exclude
$excludedLocations = @("9501")

# Get Dynamic group/groups by display name and export data to CSV
try {
    $targetedGroups = Get-ADGroup -Filter {
        DisplayName -like "*_StoreLeadership" -and 
        DisplayName -notlike "*STR*" -and 
        DisplayName -notlike "*GRP*"
    } -SearchBase "OU=O365,OU=Exchange,DC=corp,DC=gianteagle,DC=com"

    $DynamicGroupSet = foreach ($group in $targetedGroups) {
        Get-AzureADMSGroup -Id ($group.Name.Split("_")[1])
    }
    
    $DynamicGroupSet | Export-Csv -Path $reportLocations[0] -Force -NoTypeInformation

    foreach ($group in $DynamicGroupSet) {
        $store = $group.DisplayName.Split("_")[0]
        if (-not ($excludedLocations -contains $store)) {
            $storeInfo[$store] = $group.Id
        }
    }
}
catch {
    Write-Error "Failed to retrieve or export dynamic group information: $_"
    exit
}

# Process Each Store's Membership Rules
foreach ($store in $storeInfo.Keys) {
    $allAdditions = @()
    $explicitAdditions = @()

    try {
        # Extract membership rules for the current store
        $filters = ($DynamicGroupSet | Where-Object { $_.DisplayName -match "^$store" }).MembershipRule.Split('"') |
                   Where-Object { $_ -match '^(\d+|\w+([.]\w+)?@(corp[.])?gianteagle.com)$' }

        # Separate explicit additions (emails) from numeric filters
        foreach ($filter in $filters) {
            if ($filter -notmatch '^\d+$') {
                $explicitAdditions += $filter
            }
        }

        foreach ($explicitAddition in $explicitAdditions) {
            $allAdditions += "-or (user.userPrincipalName -eq "+$explicitAddition+")"
        }

        $reportHash[$store] = $allAdditions -join " "
    }
    catch {
        Write-Warning "Failed to process membership rules for store" + $store +":" $_
    }
}

# Report to Files
try {
    $reportHash | Out-File -FilePath $reportLocations[1] -Force 
    $reportHash.Keys | Out-File -FilePath $reportLocations[2] -Force 
    $reportHash.Values | Out-File -FilePath $reportLocations[3] -Force
}
catch {

    Write-Error "Failed to write report files: " + $_
}

# Update Membership Rules with New Filter and Append Prior Additions
foreach ($store in $reportHash.Keys) {
    $adds = $reportHash[$store]
    $filterRule = '(user.Department -contains ' + '"' + $store + '")' + ' -and (user.extensionAttribute3 -eq "A") -and ((user.extensionAttribute13 -In ["10015","10102","10118","80002","80012","67907","80133"]) -or (user.extensionAttribute6 -contains "10015") -or (user.extensionAttribute6 -contains "10102") -or (user.extensionAttribute6 -contains "10118") -or (user.extensionAttribute6 -contains "80002") -or (user.extensionAttribute6 -contains "80012") -or (user.extensionAttribute6 -contains "67907") -or (user.extensionAttribute6 -contains "80133"))'
    $finalRule = "$filterRule $adds"
    
    # Save the final rule to output file
    try {
        $outputRules += $finalRule
        $outputRules | Out-File -FilePath $reportLocations[4] -Force
    }
    catch {
        Write-Error "Failed to write final membership rules for store " + $store + ":" + $_
    }

    # Uncomment to set the group membership rule in Azure AD
    # Set-AzureADMSGroup -Id $storeInfo[$store] -MembershipRule $finalRule
}

# Completion Message
Write-Host "Complete" -ForegroundColor Yellow
$reportLocations | ForEach-Object { Write-Host "View report @ $_" -ForegroundColor Green }
