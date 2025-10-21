# Amazon Store Delivery Dynamic Group Management Script
# This script manages existing Amazon dynamic groups and updates their membership rules
# Based on the existing CurbsideExpress management pattern

Import-Module AzureADPreview

# Authentication check and connection
try { 
    Get-AzureADTenantDetail | Out-Null
    Write-Host "✓ Already connected to Azure AD" -ForegroundColor Green
} 
catch [Microsoft.Open.Azure.AD.CommonLibrary.AadNeedAuthenticationException] { 
    Write-Host "You're not connected to AzureAD" -ForegroundColor Yellow
    Write-Host "Connecting to Azure AD..." -ForegroundColor Yellow
    try {
        Connect-AzureAD
        Write-Host "✓ Successfully connected to Azure AD" -ForegroundColor Green
    } catch {
        Write-Host "✗ Failed to connect to Azure AD: $_" -ForegroundColor Red
        Write-Host "Please run: Connect-AzureAD" -ForegroundColor Yellow
        exit 1
    }
}

# Initialize variables
$targetedGroups = @()
$storeInfo = @{}
$reportHash = @{}
$out = @()
$adds = ""
$logPath = "C:\Temp\AmazonGroups"
$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"

# Create log directory if it doesn't exist
if (!(Test-Path $logPath)) {
    New-Item -ItemType Directory -Path $logPath -Force
}

# Exclude specific locations from any update
$excludedLocations = @("9501")

# Amazon-specific job codes for dynamic membership rule
$amazonJobCodes = @("10147","10148","10180","31310","80119","80144","80155","80189","10183","88052","80246")

Write-Host "Starting Amazon Dynamic Group Management Process..."

# Get existing Amazon groups from Active Directory
try {
    $targetedGroups = (Get-ADGroup -filter { DisplayName -like "*_AmazonDelivery" } -SearchBase "OU=O365,OU=Exchange,DC=corp,DC=gianteagle,DC=com") 
    Write-Host "Found $($targetedGroups.Count) existing Amazon groups in Active Directory"
} catch {
    Write-Error "Failed to retrieve groups from Active Directory: $_"
    exit 1
}

# Get corresponding Azure AD groups
$DynamicGroupSet = @()
foreach ($group in $targetedGroups) {
    try {
        $azureGroup = Get-AzureADMSGroup -Id $group.Name.Split("_")[1] -ErrorAction SilentlyContinue
        if ($azureGroup) {
            $DynamicGroupSet += $azureGroup
        }
    } catch {
        Write-Warning "Could not find Azure AD group for $($group.DisplayName)"
    }
}

Write-Host "Found $($DynamicGroupSet.Count) corresponding Azure AD groups"

# Export group information for reference
$DynamicGroupSet | Export-Csv -Path "$logPath\AmazonDynamicGroupSet_$timestamp.csv" -Force -NoTypeInformation

# Build store information hash
foreach ($group in $DynamicGroupSet) {
    $store = $group.DisplayName.Split("_")[0]
    if (-not ($excludedLocations -contains $store)) {
        $storeInfo.Add($store, $group.Id)
    }
}

Write-Host "Processing $($storeInfo.Count) stores for membership rule updates"

# Process each store
foreach ($store in $storeInfo.Keys) {
    $allAdditions = @()
    $ExplicitAdditions = @()
    
    Write-Host "Processing store: $store"
    
    # Get existing explicit additions from current membership rule
    $currentGroup = $DynamicGroupSet | Where-Object { $_.DisplayName -match "^$store" }
    if ($currentGroup) {
        $Filters = $currentGroup.MembershipRule.Split('"') | Where-Object { $_ -match '^\d+$' -or $_ -match '^\w+([.]\w+)?@(corp[.])?gianteagle.com$' }
        $Filters | ForEach-Object {
            if ($_ -match '^\d+$') {
                # Skip numeric filters (these are job codes)
            } else {
                $ExplicitAdditions += $_
            }
        }
    }
    
    # Build explicit additions string
    foreach ($ExplicitAddition in $ExplicitAdditions) {
        $allAdditions += " -or (user.userPrincipalName -eq " + '"' + $ExplicitAddition + '"' + ")"
    }
    
    $reportHash.Add($store, $allAdditions)
    
    # Build the complete membership rule
    $adds = $allAdditions -join ""
    $filterRule = New-AmazonMembershipRule -StoreNumber $store -JobCodes $amazonJobCodes
    $completeRule = $filterRule + $adds
    
    # Log the rule being applied
    $out += $completeRule
    $out | Out-File -FilePath "$logPath\AmazonMembershipRules_$timestamp.txt" -Force
    
    # Apply the membership rule
    try {
        Set-AzureADMSGroup -Id $storeInfo[$store] -MembershipRule $completeRule -MembershipRuleProcessingState "On"
        
        # Verify the update
        $postUpdate = Get-AzureADMSGroup -Id $storeInfo[$store]
        
        # Log the update
        $logEntry = "STORE=$store`nID=$($storeInfo[$store])`nNEW_RULE=$completeRule`nPOST_UPDATE=$($postUpdate.MembershipRule)`nUPDATED=$((Get-Date).ToString())`n"
        $logEntry | Out-File -FilePath "$logPath\AmazonGroupUpdates_$timestamp.log" -Append
        
        Write-Host "Successfully updated membership rule for store $store"
        
    } catch {
        Write-Error "Failed to update MembershipRule for store $store ($($storeInfo[$store])): $_"
        
        # Log the error
        $errorLog = "ERROR_STORE=$store`nID=$($storeInfo[$store])`nERROR=$_`nTIMESTAMP=$((Get-Date).ToString())`n"
        $errorLog | Out-File -FilePath "$logPath\AmazonGroupErrors_$timestamp.log" -Append
    }
    
    $adds = $null
}

# Generate summary report
$summaryReport = @"
Amazon Dynamic Group Management Summary
=====================================
Timestamp: $((Get-Date).ToString())
Total Groups Found: $($targetedGroups.Count)
Azure AD Groups Found: $($DynamicGroupSet.Count)
Stores Processed: $($storeInfo.Count)
Excluded Stores: $($excludedLocations.Count)

Store Details:
"@

foreach ($store in $storeInfo.Keys) {
    $summaryReport += "`nStore: $store - Group ID: $($storeInfo[$store])"
}

$summaryReport | Out-File -FilePath "$logPath\AmazonGroupManagementSummary_$timestamp.txt" -Force

Write-Host "`nAmazon Dynamic Group Management Process Complete!"
Write-Host "Summary report saved to: $logPath\AmazonGroupManagementSummary_$timestamp.txt"
Write-Host "Detailed logs saved to: $logPath\"

# Function to build Amazon-specific membership rule
function New-AmazonMembershipRule {
    param(
        [string]$StoreNumber,
        [array]$JobCodes
    )
    
    # Build the job codes part of the rule
    $jobCodeRule = "((user.extensionAttribute13 -In [`"$($JobCodes -join '","')`"])"
    foreach ($jobCode in $JobCodes) {
        $jobCodeRule += " -or (user.extensionAttribute6 -contains `"$jobCode`")"
    }
    $jobCodeRule += ")"
    
    # Build the complete membership rule
    $membershipRule = "(user.Department -contains `"$StoreNumber`") -and (user.extensionAttribute3 -eq `"A`") -and $jobCodeRule"
    
    return $membershipRule
}

# Export store information for reference
$storeInfo | ConvertTo-Json | Out-File -FilePath "$logPath\AmazonStoreManagementInfo_$timestamp.json" -Force
$storeInfo | Export-Csv -Path "$logPath\AmazonStoreManagementInfo_$timestamp.csv" -Force -NoTypeInformation

Write-Host "Store information exported to: $logPath\AmazonStoreManagementInfo_$timestamp.csv"
