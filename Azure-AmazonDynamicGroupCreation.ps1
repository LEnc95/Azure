# Amazon Store Delivery Dynamic Group Creation Script
# This script creates and configures dynamic membership rules for Amazon store delivery groups
# Based on the existing CurbsideExpress pattern

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
$amazonStores = @()
$storeInfo = @{}
$logPath = "C:\Temp\AmazonGroups"
$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"

# Create log directory if it doesn't exist
if (!(Test-Path $logPath)) {
    New-Item -ItemType Directory -Path $logPath -Force
}

# Load Amazon store locations from CSV
$csvPath = ".\Copy of Amazon ARK Expansion Locations.csv"
if (Test-Path $csvPath) {
    $amazonStores = (Import-Csv $csvPath | Where-Object { $_.Store -ne "" -and $_.Store -ne $null }).Store
    Write-Host "Loaded $($amazonStores.Count) Amazon store locations from CSV"
} else {
    Write-Error "CSV file not found at: $csvPath"
    exit 1
}

# Exclude specific locations from any update (if needed)
$excludedLocations = @()

# Amazon-specific job codes for dynamic membership rule
$amazonJobCodes = @("10147","10148","10180","31310","80119","80144","80155","80189","10183","88052","80246")

Write-Host "Starting Amazon Dynamic Group Creation Process..."
Write-Host "Processing $($amazonStores.Count) stores"

# Process each Amazon store
foreach ($store in $amazonStores) {
    if ($excludedLocations -contains $store) {
        Write-Host "Skipping excluded store: $store"
        continue
    }
    
    try {
        # Create group name for Amazon delivery
        $groupName = "${store}_AmazonDelivery"
        $groupDisplayName = "Store $store - Amazon Delivery"
        $groupDescription = "Dynamic group for Amazon delivery at store $store"
        
        Write-Host "Processing store: $store"
        
        # Check if group already exists
        $existingGroup = Get-AzureADMSGroup -Filter "displayName eq '$groupDisplayName'" -ErrorAction SilentlyContinue
        
        if ($existingGroup) {
            Write-Host "Group already exists for store $store - ID $($existingGroup.Id)"
            $storeInfo.Add($store, $existingGroup.Id)
        } else {
            # Create new dynamic group
            Write-Host "Creating new group for store: $store"
            
            # Build the dynamic membership rule for Amazon delivery
            $membershipRule = New-AmazonMembershipRule -StoreNumber $store -JobCodes $amazonJobCodes
            
            # Create the group
            $newGroup = New-AzureADMSGroup -DisplayName $groupDisplayName -Description $groupDescription -MailEnabled $false -SecurityEnabled $true -GroupTypes @("DynamicMembership") -MembershipRule $membershipRule -MembershipRuleProcessingState "On"
            
            if ($newGroup) {
                $storeInfo.Add($store, $newGroup.Id)
                Write-Host "Successfully created group for store $store with ID: $($newGroup.Id)"
                
                # Log the creation
                $logEntry = "STORE=$store`nID=$($newGroup.Id)`nGroupName=$groupName`nDisplayName=$groupDisplayName`nMembershipRule=$membershipRule`nCreated=$((Get-Date).ToString())`n"
                $logEntry | Out-File -FilePath "$logPath\AmazonGroupCreation_$timestamp.log" -Append
            } else {
                Write-Error "Failed to create group for store: $store"
            }
        }
        
        # Build and apply membership rule (for existing groups or newly created ones)
        if ($storeInfo.ContainsKey($store)) {
            $membershipRule = New-AmazonMembershipRule -StoreNumber $store -JobCodes $amazonJobCodes
            $explicitAdditions = Get-ExplicitAdditions -StoreNumber $store
            
            # Add explicit additions to the rule
            if ($explicitAdditions.Count -gt 0) {
                $membershipRule += " -or (" + ($explicitAdditions -join " -or ") + ")"
            }
            
            # Update the group with the membership rule
            try {
                Set-AzureADMSGroup -Id $storeInfo[$store] -MembershipRule $membershipRule -MembershipRuleProcessingState "On"
                
                # Verify the update
                $updatedGroup = Get-AzureADMSGroup -Id $storeInfo[$store]
                Write-Host "Successfully updated membership rule for store $store"
                
                # Log the update
                $logEntry = "STORE=$store`nID=$($storeInfo[$store])`nUpdatedRule=$membershipRule`nVerifiedRule=$($updatedGroup.MembershipRule)`nUpdated=$((Get-Date).ToString())`n"
                $logEntry | Out-File -FilePath "$logPath\AmazonGroupUpdate_$timestamp.log" -Append
                
            } catch {
                Write-Error "Failed to update membership rule for store $store`: $_"
            }
        }
        
    } catch {
        Write-Error "Error processing store $store`: $_"
    }
}

# Generate summary report
$summaryReport = @"
Amazon Dynamic Group Creation Summary
====================================
Timestamp: $((Get-Date).ToString())
Total Stores Processed: $($amazonStores.Count)
Groups Created/Updated: $($storeInfo.Count)
Excluded Stores: $($excludedLocations.Count)

Store Details:
"@

foreach ($store in $storeInfo.Keys) {
    $summaryReport += "`nStore: $store - Group ID: $($storeInfo[$store])"
}

$summaryReport | Out-File -FilePath "$logPath\AmazonGroupSummary_$timestamp.txt" -Force

Write-Host "`nAmazon Dynamic Group Creation Process Complete!"
Write-Host "Summary report saved to: $logPath\AmazonGroupSummary_$timestamp.txt"
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

# Function to get explicit additions for a store (if any)
function Get-ExplicitAdditions {
    param(
        [string]$StoreNumber
    )
    
    $explicitAdditions = @()
    
    # This function can be extended to check for any explicit user additions
    # that should be included in the dynamic group beyond the standard rules
    
    return $explicitAdditions
}

# Export store information for reference
$storeInfo | ConvertTo-Json | Out-File -FilePath "$logPath\AmazonStoreInfo_$timestamp.json" -Force
$storeInfo | Export-Csv -Path "$logPath\AmazonStoreInfo_$timestamp.csv" -Force -NoTypeInformation

Write-Host "Store information exported to: $logPath\AmazonStoreInfo_$timestamp.csv"
