# Usage Examples and Practical Scenarios

## License Management Examples

### Example 1: Analyzing User License Assignments

**Scenario:** Check if a user has direct license assignments that should be converted to group-based assignments.

```powershell
# Step 1: Import required functions
. .\licenseAssignment.ps1

# Step 2: Connect to MSOnline
Connect-MsolService

# Step 3: Get user information
$userUPN = "john.doe@company.com"
$user = Get-MsolUser -UserPrincipalName $userUPN

# Step 4: Check license assignments
$enterpriseLicense = "contoso:ENTERPRISEPACK"
$hasDirectLicense = UserHasLicenseAssignedDirectly -user $user -skuId $enterpriseLicense
$hasGroupLicense = UserHasLicenseAssignedFromGroup -user $user -skuId $enterpriseLicense

# Step 5: Report results
Write-Host "User: $userUPN"
Write-Host "Direct License: $hasDirectLicense"
Write-Host "Group License: $hasGroupLicense"

# Step 6: Take action if both exist (redundant direct assignment)
if ($hasDirectLicense -and $hasGroupLicense) {
    Write-Warning "User has both direct and group licenses - consider removing direct assignment"
    # Use removeDirectLicense.ps1 for safe removal
}
```

### Example 2: Bulk License Assignment Analysis

**Scenario:** Generate comprehensive license report for all users.

```powershell
# Step 1: Run license reporting script
.\OfficeLicenseReporting_v2.ps1

# The script will generate a CSV file with timestamp in C:\Temp\
# Example output file: C:\Temp\LicenseReport_2024-01-15_14-30.csv

# Step 2: Analyze results
$reportPath = "C:\Temp\LicenseReport_$(Get-Date -Format 'yyyy-MM-dd').csv"
$licenseData = Import-Csv -Path $reportPath

# Step 3: Find users with direct assignments
$directAssignments = $licenseData | Where-Object { $_.AssignmentType -eq "Direct" }

# Step 4: Report findings
Write-Host "Users with direct license assignments: $($directAssignments.Count)"
$directAssignments | Select-Object UserPrincipalName, LicenseSKU | Format-Table
```

### Example 3: Safe Direct License Removal

**Scenario:** Remove direct license assignments while preserving group-based assignments.

```powershell
# Step 1: Execute the removal script
.\removeDirectLicense.ps1

# Step 2: Review the generated reports
$reportDate = Get-Date -Format "yyyy-MM-dd_HH-mm"
$removalLog = "C:\Temp\DirectLicenseRemoval_$reportDate.csv"

# Step 3: Verify changes
if (Test-Path $removalLog) {
    $removalResults = Import-Csv -Path $removalLog
    $successfulRemovals = $removalResults | Where-Object { $_.Status -eq "Success" }
    $failedRemovals = $removalResults | Where-Object { $_.Status -eq "Failed" }
    
    Write-Host "Successful removals: $($successfulRemovals.Count)"
    Write-Host "Failed removals: $($failedRemovals.Count)"
    
    if ($failedRemovals) {
        Write-Warning "Review failed removals:"
        $failedRemovals | Format-Table
    }
}
```

## Dynamic Group Management Examples

### Example 4: Creating Department-Based Dynamic Groups

**Scenario:** Create dynamic groups for different departments with specific job titles.

```powershell
# Step 1: Import the function
. .\NewDynamicGroup.ps1

# Step 2: Connect to Azure AD
Import-Module AzureADPreview
Connect-AzureAD

# Step 3: Define group parameters
$departments = @(
    @{
        Name = "IT-Managers"
        Description = "IT Department Managers"
        MailNickName = "itmanagers"
        Rule = "(user.department -eq 'IT') -and (user.jobTitle -contains 'Manager')"
    },
    @{
        Name = "Sales-Team"
        Description = "Sales Department Team"
        MailNickName = "salesteam"
        Rule = "(user.department -eq 'Sales')"
    },
    @{
        Name = "Remote-Workers"
        Description = "Remote Workers in IT and Sales"
        MailNickName = "remoteworkers"
        Rule = "((user.department -eq 'IT') -or (user.department -eq 'Sales')) -and (user.extensionAttribute1 -eq 'Remote')"
    }
)

# Step 4: Create groups
foreach ($group in $departments) {
    try {
        New-DynamicGroup -DisplayName $group.Name -Description $group.Description -MailNickName $group.MailNickName -MembershipRule $group.Rule
        Write-Host "Successfully created group: $($group.Name)" -ForegroundColor Green
    }
    catch {
        Write-Error "Failed to create group $($group.Name): $($_.Exception.Message)"
    }
}
```

### Example 5: Bulk Dynamic Group Updates

**Scenario:** Update membership rules for multiple store-based groups.

```powershell
# Step 1: Configure target groups (modify these variables in the script)
# Edit UpdateDynamicGroups.ps1 and set:
# $targetedGroups = Get-ADGroup -filter { DisplayName -like "*_StoreLeadership" }

# Step 2: Execute the update script
.\UpdateDynamicGroups.ps1

# Step 3: Review generated reports
$timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm"
$reportFiles = @(
    "C:\Temp\DynamicGroupSet_$timestamp.csv",
    "C:\Temp\reportHash_$timestamp.txt",
    "C:\Temp\reportStores_$timestamp.txt",
    "C:\Temp\reportAdds_$timestamp.txt"
)

# Step 4: Analyze results
foreach ($file in $reportFiles) {
    if (Test-Path $file) {
        Write-Host "Report generated: $file"
        # Review file contents as needed
    }
}
```

### Example 6: Store-Specific Group Management

**Scenario:** Manage Key Carrier groups for specific stores.

```powershell
# Step 1: Execute the store-specific script
.\Azure-DynamicGroup-SetMembershipRule.ps1

# This script will:
# - Search for Key Carrier groups in AD
# - Build dynamic group set from Azure AD
# - Format store information mapping
# - Apply new membership rules

# Step 2: Verify group updates
$keyCarrierGroups = Get-AzureADMSGroup -Filter "displayName like '*Key_Carriers'"
$keyCarrierGroups | Select-Object DisplayName, MembershipRule, MembershipRuleProcessingState | Format-Table -Wrap
```

## User Account Management Examples

### Example 7: Inactive User Management

**Scenario:** Identify and process inactive users with comprehensive reporting.

```powershell
# Step 1: Configure exclusion list
$exclusionFile = "C:\Temp\inactiveExclusion.txt"
@"
admin@company.com
service.account@company.com
emergency.access@company.com
"@ | Out-File -FilePath $exclusionFile

# Step 2: Execute inactive user processing
.\inactiveUsersV2.ps1

# Step 3: Review results
$reportDate = Get-Date -Format "yyyy-MM-dd"
$inactiveReport = "C:\Temp\InactiveUsers_$reportDate.csv"

if (Test-Path $inactiveReport) {
    $inactiveUsers = Import-Csv -Path $inactiveReport
    
    # Analyze results
    $expiredUsers = $inactiveUsers | Where-Object { $_.AccountExpired -eq $true }
    $flaggedUsers = $inactiveUsers | Where-Object { $_.ToBeExpired -eq $true }
    
    Write-Host "Inactive Users Summary:"
    Write-Host "Already Expired: $($expiredUsers.Count)"
    Write-Host "Flagged for Expiration: $($flaggedUsers.Count)"
    
    # Review flagged users before expiration
    if ($flaggedUsers) {
        Write-Host "`nUsers flagged for expiration:"
        $flaggedUsers | Select-Object UserPrincipalName, LastLogonDate, LastAzureSignIn | Format-Table
    }
}
```

### Example 8: Cloud Account Validation

**Scenario:** Validate cloud account status and configurations.

```powershell
# Step 1: Execute cloud account check
.\CloudAccountCheck.ps1

# The script will perform:
# - Azure account validation
# - Exchange Online checks
# - License verification
# - MFA status review

# Step 2: Review generated reports
$cloudCheckReport = "C:\Temp\CloudAccountCheck_$(Get-Date -Format 'yyyy-MM-dd').csv"

if (Test-Path $cloudCheckReport) {
    $accountData = Import-Csv -Path $cloudCheckReport
    
    # Identify accounts needing attention
    $issueAccounts = $accountData | Where-Object { 
        $_.AzureStatus -ne "Active" -or 
        $_.ExchangeStatus -ne "Active" -or 
        $_.LicenseStatus -ne "Valid" 
    }
    
    if ($issueAccounts) {
        Write-Warning "Accounts requiring attention: $($issueAccounts.Count)"
        $issueAccounts | Format-Table
    }
}
```

## MFA Management Examples

### Example 9: Department MFA Enrollment Report

**Scenario:** Generate MFA enrollment report for specific department.

```powershell
# Step 1: Modify department filter in Report_MFA_Enrollment.ps1
# Edit the script to change: $users = get-aduser -Filter {department -like "6376"}
# To your target department

# Step 2: Execute MFA reporting
.\Report_MFA_Enrollment.ps1

# Step 3: Analyze MFA enrollment results
$mfaReport = "C:\Temp\MFAEnrollment.csv"
$mfaData = Import-Csv -Path $mfaReport

# Step 4: Generate summary statistics
$totalUsers = $mfaData.Count
$enrolledUsers = $mfaData | Where-Object { $_.MFAType -ne "" -and $_.MFAType -ne $null }
$enforcedUsers = $mfaData | Where-Object { $_.MFAEnforced -eq $true }

Write-Host "MFA Enrollment Summary:"
Write-Host "Total Users: $totalUsers"
Write-Host "Enrolled Users: $($enrolledUsers.Count) ($([math]::Round(($enrolledUsers.Count / $totalUsers) * 100, 2))%)"
Write-Host "Enforced Users: $($enforcedUsers.Count) ($([math]::Round(($enforcedUsers.Count / $totalUsers) * 100, 2))%)"

# Step 5: Identify users needing MFA setup
$needsMFA = $mfaData | Where-Object { $_.MFAType -eq "" -or $_.MFAType -eq $null }
if ($needsMFA) {
    Write-Host "`nUsers needing MFA setup:"
    $needsMFA | Select-Object DisplayName, UserPrincipalName | Format-Table
}
```

### Example 10: MFA Method Analysis

**Scenario:** Analyze MFA methods across the organization.

```powershell
# Step 1: Import MFA report data
$mfaReport = "C:\Temp\MFAEnrollment.csv"
$mfaData = Import-Csv -Path $mfaReport

# Step 2: Analyze MFA methods
$mfaMethodStats = $mfaData | Group-Object MFAType | Select-Object Name, Count, @{
    Name = "Percentage"
    Expression = { [math]::Round(($_.Count / $mfaData.Count) * 100, 2) }
}

Write-Host "MFA Method Distribution:"
$mfaMethodStats | Format-Table -AutoSize

# Step 3: Identify security concerns
$smsUsers = $mfaData | Where-Object { $_.MFAType -eq "SMS token" }
if ($smsUsers) {
    Write-Warning "Users using less secure SMS tokens: $($smsUsers.Count)"
    Write-Host "Consider migrating to authenticator apps for enhanced security."
}
```

## Password Policy Management Examples

### Example 11: Password Policy Synchronization Check

**Scenario:** Verify password policy synchronization between on-premises and cloud.

```powershell
# Step 1: Execute password policy check
.\checkPassPol_inSync.ps1

# Step 2: Review synchronization results
$syncReport = "C:\Temp\checkPassPol_inSync.csv"
$syncData = Import-Csv -Path $syncReport

# Step 3: Identify synchronization issues
$syncIssues = $syncData | Where-Object { $_.InSync -eq $false }

if ($syncIssues) {
    Write-Warning "Password policy synchronization issues found: $($syncIssues.Count)"
    $syncIssues | Select-Object UserPrincipalName, OnPremPolicy, CloudPolicy, Issue | Format-Table
}

# Step 4: Generate compliance report
$complianceReport = @{
    TotalUsers = $syncData.Count
    InSync = ($syncData | Where-Object { $_.InSync -eq $true }).Count
    OutOfSync = $syncIssues.Count
    ComplianceRate = [math]::Round((($syncData.Count - $syncIssues.Count) / $syncData.Count) * 100, 2)
}

Write-Host "Password Policy Compliance Summary:"
Write-Host "Total Users: $($complianceReport.TotalUsers)"
Write-Host "In Sync: $($complianceReport.InSync)"
Write-Host "Out of Sync: $($complianceReport.OutOfSync)"
Write-Host "Compliance Rate: $($complianceReport.ComplianceRate)%"
```

### Example 12: Password Expiration Management

**Scenario:** Check and manage password expiration settings.

```powershell
# Step 1: Execute password expiration check
.\passwordExpirationCheck.ps1

# Step 2: Connect to MSOnline for detailed analysis
Connect-MsolService

# Step 3: Get users with expiring passwords
$expiringPasswords = Get-MsolUser -All | Where-Object {
    $_.PasswordNeverExpires -eq $false -and
    $_.LastPasswordChangeTimestamp -lt (Get-Date).AddDays(-75)  # Assuming 90-day policy
}

# Step 4: Generate expiration report
$expirationReport = foreach ($user in $expiringPasswords) {
    $daysSinceChange = (Get-Date) - $user.LastPasswordChangeTimestamp
    [PSCustomObject]@{
        UserPrincipalName = $user.UserPrincipalName
        DisplayName = $user.DisplayName
        LastPasswordChange = $user.LastPasswordChangeTimestamp
        DaysSinceChange = [math]::Round($daysSinceChange.Days, 0)
        DaysUntilExpiration = 90 - [math]::Round($daysSinceChange.Days, 0)
    }
}

# Step 5: Export and display results
$expirationReport | Export-Csv -Path "C:\Temp\PasswordExpiration_$(Get-Date -Format 'yyyy-MM-dd').csv" -NoTypeInformation
$expirationReport | Sort-Object DaysUntilExpiration | Format-Table
```

## Automation and Bulk Operations Examples

### Example 13: Automated License Cleanup Workflow

**Scenario:** Implement a complete automated license cleanup process.

```powershell
# Complete automated workflow script
param(
    [switch]$WhatIf = $false,
    [string]$ReportPath = "C:\Temp\LicenseCleanup_$(Get-Date -Format 'yyyy-MM-dd_HH-mm')"
)

# Step 1: Create report directory
New-Item -Path $ReportPath -ItemType Directory -Force

# Step 2: Generate initial license report
Write-Host "Generating license assignment report..." -ForegroundColor Yellow
.\OfficeLicenseReporting_v2.ps1

# Step 3: Analyze current state
$licenseReport = Get-ChildItem "C:\Temp" -Filter "LicenseReport_*.csv" | Sort-Object LastWriteTime -Descending | Select-Object -First 1
$licenseData = Import-Csv -Path $licenseReport.FullName

# Step 4: Identify cleanup candidates
$cleanupCandidates = $licenseData | Where-Object { 
    $_.DirectAssignment -eq $true -and 
    $_.GroupAssignment -eq $true 
}

Write-Host "Found $($cleanupCandidates.Count) users with redundant direct assignments"

# Step 5: Execute cleanup (if not WhatIf)
if (-not $WhatIf) {
    Write-Host "Executing license cleanup..." -ForegroundColor Yellow
    .\removeDirectLicense.ps1
} else {
    Write-Host "WhatIf mode: No changes will be made"
    $cleanupCandidates | Select-Object UserPrincipalName, LicenseSKU | Format-Table
}

# Step 6: Generate final report
$finalReport = @{
    ExecutionTime = Get-Date
    TotalUsersAnalyzed = $licenseData.Count
    CleanupCandidates = $cleanupCandidates.Count
    WhatIfMode = $WhatIf
    ReportLocation = $ReportPath
}

$finalReport | ConvertTo-Json | Out-File -FilePath "$ReportPath\Summary.json"
Write-Host "Automation completed. Report saved to: $ReportPath"
```

### Example 14: Dynamic Group Batch Creation

**Scenario:** Create multiple dynamic groups based on organizational structure.

```powershell
# Define organizational structure
$orgStructure = @{
    "IT" = @{
        "IT-All" = "(user.department -eq 'IT')"
        "IT-Managers" = "(user.department -eq 'IT') -and (user.jobTitle -contains 'Manager')"
        "IT-Developers" = "(user.department -eq 'IT') -and (user.jobTitle -contains 'Developer')"
        "IT-Support" = "(user.department -eq 'IT') -and (user.jobTitle -contains 'Support')"
    }
    "Sales" = @{
        "Sales-All" = "(user.department -eq 'Sales')"
        "Sales-Managers" = "(user.department -eq 'Sales') -and (user.jobTitle -contains 'Manager')"
        "Sales-Reps" = "(user.department -eq 'Sales') -and (user.jobTitle -contains 'Representative')"
    }
    "HR" = @{
        "HR-All" = "(user.department -eq 'HR')"
        "HR-Managers" = "(user.department -eq 'HR') -and (user.jobTitle -contains 'Manager')"
    }
}

# Import required modules and functions
Import-Module AzureADPreview
Connect-AzureAD
. .\NewDynamicGroup.ps1

# Create groups
foreach ($department in $orgStructure.Keys) {
    Write-Host "Creating groups for department: $department" -ForegroundColor Green
    
    foreach ($groupName in $orgStructure[$department].Keys) {
        $rule = $orgStructure[$department][$groupName]
        $mailNickName = $groupName.ToLower().Replace("-", "")
        
        try {
            New-DynamicGroup -DisplayName $groupName -Description "Dynamic group for $groupName" -MailNickName $mailNickName -MembershipRule $rule
            Write-Host "  ✓ Created: $groupName" -ForegroundColor Gray
        }
        catch {
            Write-Error "  ✗ Failed to create $groupName: $($_.Exception.Message)"
        }
    }
}
```

## Monitoring and Reporting Examples

### Example 15: Comprehensive Health Check

**Scenario:** Perform a comprehensive health check across all Azure AD services.

```powershell
# Comprehensive Azure AD health check script
param(
    [string]$OutputPath = "C:\Temp\HealthCheck_$(Get-Date -Format 'yyyy-MM-dd_HH-mm')"
)

# Create output directory
New-Item -Path $OutputPath -ItemType Directory -Force

Write-Host "Starting Azure AD Health Check..." -ForegroundColor Green

# 1. License Health Check
Write-Host "Checking license assignments..." -ForegroundColor Yellow
.\OfficeLicenseReporting_v2.ps1
$licenseReport = Get-ChildItem "C:\Temp" -Filter "LicenseReport_*.csv" | Sort-Object LastWriteTime -Descending | Select-Object -First 1
Copy-Item $licenseReport.FullName -Destination "$OutputPath\LicenseHealth.csv"

# 2. MFA Enrollment Check
Write-Host "Checking MFA enrollment..." -ForegroundColor Yellow
.\Report_MFA_Enrollment.ps1
Copy-Item "C:\Temp\MFAEnrollment.csv" -Destination "$OutputPath\MFAHealth.csv"

# 3. Inactive Users Check
Write-Host "Checking inactive users..." -ForegroundColor Yellow
.\inactiveUsersV2.ps1
$inactiveReport = Get-ChildItem "C:\Temp" -Filter "InactiveUsers_*.csv" | Sort-Object LastWriteTime -Descending | Select-Object -First 1
Copy-Item $inactiveReport.FullName -Destination "$OutputPath\InactiveUsersHealth.csv"

# 4. Password Policy Check
Write-Host "Checking password policies..." -ForegroundColor Yellow
.\checkPassPol_inSync.ps1
Copy-Item "C:\Temp\checkPassPol_inSync.csv" -Destination "$OutputPath\PasswordPolicyHealth.csv"

# 5. Generate Health Summary
$healthSummary = @{
    CheckDate = Get-Date
    LicenseIssues = (Import-Csv "$OutputPath\LicenseHealth.csv" | Where-Object { $_.Issue -ne $null }).Count
    MFAUnenrolled = (Import-Csv "$OutputPath\MFAHealth.csv" | Where-Object { $_.MFAType -eq "" }).Count
    InactiveUsers = (Import-Csv "$OutputPath\InactiveUsersHealth.csv" | Where-Object { $_.ToBeExpired -eq $true }).Count
    PasswordPolicyIssues = (Import-Csv "$OutputPath\PasswordPolicyHealth.csv" | Where-Object { $_.InSync -eq $false }).Count
}

$healthSummary | ConvertTo-Json | Out-File -FilePath "$OutputPath\HealthSummary.json"

Write-Host "Health check completed. Results saved to: $OutputPath" -ForegroundColor Green
```

## Error Handling and Troubleshooting Examples

### Example 16: Robust Script Execution with Error Handling

**Scenario:** Execute scripts with comprehensive error handling and logging.

```powershell
# Robust script execution framework
function Invoke-ScriptWithLogging {
    param(
        [string]$ScriptPath,
        [string]$LogPath = "C:\Temp\ScriptExecution.log",
        [switch]$StopOnError = $false
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] Starting execution of $ScriptPath"
    
    try {
        Add-Content -Path $LogPath -Value $logEntry
        
        # Execute script and capture output
        $result = & $ScriptPath 2>&1
        
        if ($LASTEXITCODE -eq 0) {
            $successEntry = "[$timestamp] SUCCESS: $ScriptPath completed successfully"
            Add-Content -Path $LogPath -Value $successEntry
            Write-Host $successEntry -ForegroundColor Green
        } else {
            $errorEntry = "[$timestamp] ERROR: $ScriptPath failed with exit code $LASTEXITCODE"
            Add-Content -Path $LogPath -Value $errorEntry
            Add-Content -Path $LogPath -Value "Output: $result"
            Write-Error $errorEntry
            
            if ($StopOnError) {
                throw "Script execution failed: $ScriptPath"
            }
        }
    }
    catch {
        $exceptionEntry = "[$timestamp] EXCEPTION: $($_.Exception.Message)"
        Add-Content -Path $LogPath -Value $exceptionEntry
        Write-Error $exceptionEntry
        
        if ($StopOnError) {
            throw
        }
    }
}

# Example usage
$scripts = @(
    ".\OfficeLicenseReporting_v2.ps1",
    ".\Report_MFA_Enrollment.ps1",
    ".\inactiveUsersV2.ps1"
)

foreach ($script in $scripts) {
    Invoke-ScriptWithLogging -ScriptPath $script -LogPath "C:\Temp\ExecutionLog.txt"
}
```

This comprehensive usage guide provides practical examples for all major functionality in the Azure AD management script collection. Each example includes step-by-step instructions, error handling, and result analysis to help administrators effectively use these tools in their environment.