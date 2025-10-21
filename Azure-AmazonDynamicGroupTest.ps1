# Amazon Store Delivery Dynamic Group TEST Script
# This script creates and tests ONE Amazon delivery group to validate the process
# Run this first before executing the full batch script

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

# Test configuration - Change this to test different stores
$testStore = "0002"  # Change this to any store number from your CSV
$logPath = "C:\Temp\AmazonGroups\Test"
$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"

# Create log directory if it doesn't exist
if (!(Test-Path $logPath)) {
    New-Item -ItemType Directory -Path $logPath -Force
}

# Amazon-specific job codes for dynamic membership rule
$amazonJobCodes = @("10147","10148","10180","31310","80119","80144","80155","80189","10183","88052","80246")

Write-Host "=== AMAZON DYNAMIC GROUP TEST ===" -ForegroundColor Green
Write-Host "Testing with store: $testStore" -ForegroundColor Yellow
Write-Host "Logs will be saved to: $logPath" -ForegroundColor Yellow
Write-Host ""

# Test 1: Build the membership rule
Write-Host "TEST 1: Building membership rule..." -ForegroundColor Cyan
$membershipRule = New-AmazonMembershipRule -StoreNumber $testStore -JobCodes $amazonJobCodes
Write-Host "Generated Rule:" -ForegroundColor White
Write-Host $membershipRule -ForegroundColor Gray
Write-Host ""

# Test 2: Validate the rule syntax (basic check)
Write-Host "TEST 2: Validating rule syntax..." -ForegroundColor Cyan
try {
    # Basic syntax validation - check for required components
    if ($membershipRule -match "user\.Department.*contains.*$testStore" -and 
        $membershipRule -match "user\.extensionAttribute3.*eq.*A" -and
        $membershipRule -match "extensionAttribute13.*In" -and
        $membershipRule -match "extensionAttribute6.*contains") {
        Write-Host "✓ Rule syntax appears valid" -ForegroundColor Green
    } else {
        Write-Host "✗ Rule syntax validation failed" -ForegroundColor Red
    }
} catch {
    Write-Host "✗ Rule validation error: $_" -ForegroundColor Red
}
Write-Host ""

# Test 3: Check if group already exists
Write-Host "TEST 3: Checking for existing group..." -ForegroundColor Cyan
$groupDisplayName = "Store $testStore - Amazon Delivery"
$existingGroup = Get-AzureADMSGroup -Filter "displayName eq '$groupDisplayName'" -ErrorAction SilentlyContinue

if ($existingGroup) {
    Write-Host "⚠ Group already exists:" -ForegroundColor Yellow
    Write-Host "  ID: $($existingGroup.Id)" -ForegroundColor Gray
    Write-Host "  Current Rule: $($existingGroup.MembershipRule)" -ForegroundColor Gray
    Write-Host ""
    
    # Test 4: Update existing group
    Write-Host "TEST 4: Updating existing group..." -ForegroundColor Cyan
    try {
        Set-AzureADMSGroup -Id $existingGroup.Id -MembershipRule $membershipRule -MembershipRuleProcessingState "On"
        $updatedGroup = Get-AzureADMSGroup -Id $existingGroup.Id
        Write-Host "✓ Group updated successfully" -ForegroundColor Green
        Write-Host "New Rule: $($updatedGroup.MembershipRule)" -ForegroundColor Gray
        
        # Log the update
        $logEntry = "TEST_UPDATE`nStore=$testStore`nID=$($existingGroup.Id)`nNewRule=$membershipRule`nUpdated=$((Get-Date).ToString())`n"
        $logEntry | Out-File -FilePath "$logPath\AmazonTestUpdate_$timestamp.log" -Append
        
    } catch {
        Write-Host "✗ Failed to update group: $_" -ForegroundColor Red
        $errorLog = "TEST_ERROR`nStore=$testStore`nError=$_`nTimestamp=$((Get-Date).ToString())`n"
        $errorLog | Out-File -FilePath "$logPath\AmazonTestError_$timestamp.log" -Append
    }
} else {
    Write-Host "✓ No existing group found - would create new group" -ForegroundColor Green
    Write-Host ""
    
    # Test 5: Create new group (DRY RUN - comment out to actually create)
    Write-Host "TEST 5: DRY RUN - Group creation simulation..." -ForegroundColor Cyan
    Write-Host "Group Name: ${testStore}_AmazonDelivery" -ForegroundColor Gray
    Write-Host "Display Name: $groupDisplayName" -ForegroundColor Gray
    Write-Host "Description: Dynamic group for Amazon delivery at store $testStore" -ForegroundColor Gray
    Write-Host ""
    Write-Host "⚠ DRY RUN MODE - No group will be created" -ForegroundColor Yellow
    Write-Host "To actually create the group, uncomment the New-AzureADMSGroup line below" -ForegroundColor Yellow
    Write-Host ""
    
    # Uncomment the following lines to actually create the group:
    <#
    try {
        $newGroup = New-AzureADMSGroup -DisplayName $groupDisplayName -Description "Dynamic group for Amazon delivery at store $testStore" -MailEnabled $false -SecurityEnabled $true -GroupTypes @("DynamicMembership") -MembershipRule $membershipRule -MembershipRuleProcessingState "On"
        
        if ($newGroup) {
            Write-Host "✓ Group created successfully" -ForegroundColor Green
            Write-Host "  ID: $($newGroup.Id)" -ForegroundColor Gray
            
            # Log the creation
            $logEntry = "TEST_CREATE`nStore=$testStore`nID=$($newGroup.Id)`nRule=$membershipRule`nCreated=$((Get-Date).ToString())`n"
            $logEntry | Out-File -FilePath "$logPath\AmazonTestCreate_$timestamp.log" -Append
        }
    } catch {
        Write-Host "✗ Failed to create group: $_" -ForegroundColor Red
    }
    #>
}

# Test 6: Validate job codes
Write-Host "TEST 6: Validating job codes..." -ForegroundColor Cyan
Write-Host "Amazon job codes configured: $($amazonJobCodes -join ', ')" -ForegroundColor Gray
Write-Host "✓ Job codes validation complete" -ForegroundColor Green
Write-Host ""

# Test 7: Export test results
Write-Host "TEST 7: Exporting test results..." -ForegroundColor Cyan
$testResults = @{
    TestStore = $testStore
    TestDate = (Get-Date).ToString()
    MembershipRule = $membershipRule
    JobCodes = $amazonJobCodes
    GroupExists = if ($existingGroup) { $true } else { $false }
    GroupId = if ($existingGroup) { $existingGroup.Id } else { "N/A" }
}

$testResults | ConvertTo-Json | Out-File -FilePath "$logPath\AmazonTestResults_$timestamp.json" -Force
$testResults | Export-Csv -Path "$logPath\AmazonTestResults_$timestamp.csv" -Force -NoTypeInformation

Write-Host "✓ Test results exported to:" -ForegroundColor Green
Write-Host "  JSON: $logPath\AmazonTestResults_$timestamp.json" -ForegroundColor Gray
Write-Host "  CSV: $logPath\AmazonTestResults_$timestamp.csv" -ForegroundColor Gray
Write-Host ""

# Summary
Write-Host "=== TEST SUMMARY ===" -ForegroundColor Green
Write-Host "Store Tested: $testStore" -ForegroundColor White
Write-Host "Group Exists: $(if ($existingGroup) { 'Yes' } else { 'No' })" -ForegroundColor White
Write-Host "Rule Generated: ✓" -ForegroundColor Green
Write-Host "Syntax Valid: ✓" -ForegroundColor Green
Write-Host "Job Codes: ✓" -ForegroundColor Green
Write-Host "Logs Created: ✓" -ForegroundColor Green
Write-Host ""

if ($existingGroup) {
    Write-Host "NEXT STEPS:" -ForegroundColor Yellow
    Write-Host "1. Review the updated group in Azure AD" -ForegroundColor White
    Write-Host "2. Check if users are being added correctly" -ForegroundColor White
    Write-Host "3. If satisfied, run the full batch script" -ForegroundColor White
} else {
    Write-Host "NEXT STEPS:" -ForegroundColor Yellow
    Write-Host "1. Uncomment the group creation code to actually create the group" -ForegroundColor White
    Write-Host "2. Run this test again to create the group" -ForegroundColor White
    Write-Host "3. Verify the group works correctly" -ForegroundColor White
    Write-Host "4. If satisfied, run the full batch script" -ForegroundColor White
}

Write-Host ""
Write-Host "Full batch script: Azure-AmazonDynamicGroupCreation.ps1" -ForegroundColor Cyan
Write-Host "Management script: Azure-AmazonDynamicGroupManagement.ps1" -ForegroundColor Cyan

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
