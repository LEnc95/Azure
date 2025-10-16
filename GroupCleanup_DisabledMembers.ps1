<#
.SYNOPSIS
    Report on security groups where a specified percentage or more of members are disabled,
    OR groups that are empty. Includes recursive membership evaluation
    and deduplication for both AD and Entra ID (Microsoft Graph).

.DESCRIPTION
    This script analyzes security groups in both Active Directory and Entra ID (Azure AD)
    to identify groups that may be inactive due to high percentages of disabled members
    or empty membership. It performs recursive membership evaluation to get all nested
    group members and provides detailed reporting with CSV export capabilities.

.PARAMETER ThresholdPercent
    The minimum percentage of disabled members required to flag a group as inactive.
    Default is 10%.

.PARAMETER IncludeEmptyGroups
    Include groups with no members in the report. Default is $true.

.PARAMETER ExportPath
    Path for the CSV export file. Default is current directory with timestamp.

.PARAMETER ShowProgress
    Display progress indicators during processing. Default is $true.

.PARAMETER MaxGroups
    Maximum number of groups to process (0 = no limit). Default is 0.

.EXAMPLE
    .\sg_cleanup_du.ps1 -ThresholdPercent 15 -ShowProgress $true

.EXAMPLE
    .\sg_cleanup_du.ps1 -ThresholdPercent 20 -IncludeEmptyGroups $false -ExportPath "C:\Reports\"

.NOTES
    Requires:
    - ActiveDirectory PowerShell module
    - Microsoft.Graph PowerShell module
    - Appropriate permissions for both AD and Entra ID

    Author: Azure Admin Team
    Version: 2.0
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [ValidateRange(1, 100)]
    [int]$ThresholdPercent = 10,
    
    [Parameter(Mandatory = $false)]
    [bool]$IncludeEmptyGroups = $true,
    
    [Parameter(Mandatory = $false)]
    [string]$ExportPath = "",
    
    [Parameter(Mandatory = $false)]
    [bool]$ShowProgress = $true,
    
    [Parameter(Mandatory = $false)]
    [ValidateRange(0, [int]::MaxValue)]
    [int]$MaxGroups = 0
)

# Initialize script variables
$ErrorActionPreference = "Continue"
$ProgressPreference = if ($ShowProgress) { "Continue" } else { "SilentlyContinue" }
$script:StartTime = Get-Date
$script:ProcessedGroups = 0
$script:TotalGroups = 0

# --- Helper Functions ---
function Write-LogMessage {
    param(
        [string]$Message,
        [string]$Level = "Info"
    )
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $color = switch ($Level) {
        "Error" { "Red" }
        "Warning" { "Yellow" }
        "Success" { "Green" }
        default { "White" }
    }
    Write-Host "[$timestamp] [$Level] $Message" -ForegroundColor $color
}

function Test-ADConnection {
    try {
        $null = Get-ADDomain -ErrorAction Stop
        return $true
    }
    catch {
        Write-LogMessage "Active Directory connection failed: $($_.Exception.Message)" "Error"
        return $false
    }
}

function Test-GraphConnection {
    try {
        $null = Get-MgContext -ErrorAction Stop
        return $true
    }
    catch {
        Write-LogMessage "Microsoft Graph connection not found" "Warning"
        return $false
    }
}

# --- Active Directory Section ---
Write-LogMessage "Starting Active Directory analysis..." "Info"

if (-not (Test-ADConnection)) {
    Write-LogMessage "Skipping Active Directory analysis due to connection issues" "Warning"
    $adResults = @()
} else {
    function Get-ADGroupRecursiveMembers {
        param(
            [Parameter(Mandatory)]
            [string]$GroupDN,
            [System.Collections.Generic.HashSet[string]]$VisitedGroupDns,
            [int]$MaxDepth = 10,
            [int]$CurrentDepth = 0
        )

        if ($CurrentDepth -ge $MaxDepth) {
            Write-LogMessage "Maximum recursion depth reached for group: $GroupDN" "Warning"
            return @()
        }

        if (-not $VisitedGroupDns) {
            $VisitedGroupDns = [System.Collections.Generic.HashSet[string]]::new()
        }

        if ($VisitedGroupDns.Contains($GroupDN)) {
            return @()
        }
        $null = $VisitedGroupDns.Add($GroupDN)

        $allMembers = New-Object System.Collections.Generic.List[object]
        
        try {
            $members = Get-ADGroupMember -Identity $GroupDN -ErrorAction Stop
            foreach ($m in $members) {
                if ($m.ObjectClass -eq "group") {
                    $nestedMembers = Get-ADGroupRecursiveMembers -GroupDN $m.DistinguishedName -VisitedGroupDns $VisitedGroupDns -MaxDepth $MaxDepth -CurrentDepth ($CurrentDepth + 1)
                    $allMembers.AddRange($nestedMembers)
                } elseif ($m.ObjectClass -eq "user") {
                    try {
                        $user = Get-ADUser -Identity $m.DistinguishedName -Properties Enabled -ErrorAction Stop
                        if ($null -ne $user) { 
                            $allMembers.Add($user) 
                        }
                    }
                    catch {
                        Write-LogMessage "Failed to get user details for $($m.DistinguishedName): $($_.Exception.Message)" "Warning"
                    }
                }
            }
        }
        catch {
            Write-LogMessage "Failed to get members for group $GroupDN : $($_.Exception.Message)" "Warning"
        }
        
        return $allMembers
    }

    try {
        Write-LogMessage "Retrieving Active Directory security groups..." "Info"
        # Some environments don't support synthetic properties like MemberCount. Request only valid attributes.
        $adGroups = Get-ADGroup -Filter "GroupCategory -eq 'Security'" -Properties GroupCategory, whenCreated, whenChanged
        
        if ($MaxGroups -gt 0 -and $adGroups.Count -gt $MaxGroups) {
            $adGroups = $adGroups | Select-Object -First $MaxGroups
            Write-LogMessage "Limited to first $MaxGroups groups due to MaxGroups parameter" "Info"
        }
        
        $script:TotalGroups += $adGroups.Count
        Write-LogMessage "Found $($adGroups.Count) security groups to analyze" "Info"
    }
    catch {
        Write-LogMessage "Failed to retrieve AD groups: $($_.Exception.Message)" "Error"
        $adGroups = @()
    }
    
    $adResults = @()
    $adGroupCount = 0
    
    foreach ($group in $adGroups) {
        $adGroupCount++
        $script:ProcessedGroups++
        
        if ($ShowProgress) {
            $percentComplete = [math]::Round(($adGroupCount / $adGroups.Count) * 100, 1)
            Write-Progress -Activity "Analyzing AD Groups" -Status "Processing $($group.Name)" -PercentComplete $percentComplete
        }
        
        try {
            Write-LogMessage "Analyzing AD group: $($group.Name) ($adGroupCount of $($adGroups.Count))" "Info"
            
            $members = Get-ADGroupRecursiveMembers -GroupDN $group.DistinguishedName
            $uniqueMembers = $members | Sort-Object DistinguishedName -Unique
            $memberCount = ($uniqueMembers | Measure-Object).Count

            if ($memberCount -eq 0) {
                if ($IncludeEmptyGroups) {
                    $adResults += [PSCustomObject]@{
                        Source        = "Active Directory"
                        GroupName     = $group.Name
                        GroupIdOrDN   = $group.DistinguishedName
                        TotalMembers  = 0
                        DisabledCount = 0
                        DisabledPct   = "N/A"
                        Status        = "Inactive (Empty)"
                        LastModified  = $group.whenChanged
                        Created       = $group.whenCreated
                    }
                }
                continue
            }

            $disabledMembers = $uniqueMembers | Where-Object { $_.Enabled -eq $false }
            $disabledPercent = [math]::Round((($disabledMembers.Count / $memberCount) * 100), 2)

            if ($disabledPercent -ge $ThresholdPercent) {
                $adResults += [PSCustomObject]@{
                    Source        = "Active Directory"
                    GroupName     = $group.Name
                    GroupIdOrDN   = $group.DistinguishedName
                    TotalMembers  = $memberCount
                    DisabledCount = $disabledMembers.Count
                    DisabledPct   = "$disabledPercent %"
                    Status        = "Inactive (Disabled ≥$ThresholdPercent%)"
                    LastModified  = $group.whenChanged
                    Created       = $group.whenCreated
                }
            }
        }
        catch {
            Write-LogMessage "Error processing AD group $($group.Name): $($_.Exception.Message)" "Error"
        }
    }
    
    Write-Progress -Activity "Analyzing AD Groups" -Completed
    Write-LogMessage "Completed AD analysis. Found $($adResults.Count) groups meeting criteria" "Success"
}

# --- Entra ID Section (Microsoft Graph) ---
Write-LogMessage "Starting Entra ID (Microsoft Graph) analysis..." "Info"

function Test-GraphConnectionAndConnect {
    if (-not (Test-GraphConnection)) {
        try {
            Write-LogMessage "Connecting to Microsoft Graph..." "Info"
            Connect-MgGraph -Scopes "Group.Read.All","User.Read.All" -ErrorAction Stop | Out-Null
            $ctx = Get-MgContext
            $scopeList = ($ctx.Scopes -join ', ')
            Write-LogMessage "Successfully connected to Microsoft Graph. Tenant: $($ctx.TenantId) Account: $($ctx.Account) Scopes: $scopeList" "Success"
            return $true
        }
        catch {
            Write-LogMessage "Failed to connect to Microsoft Graph: $($_.Exception.Message)" "Error"
            return $false
        }
    }
    return $true
}

# Fetch all transitive user members for a group with selected fields in one paged call
function Get-GraphGroupTransitiveUsers {
    param(
        [Parameter(Mandatory)]
        [string]$GroupId,
        [int]$MaxRetries = 3
    )

    $users = New-Object System.Collections.Generic.List[object]
    $retryCount = 0

    do {
        try {
            # Use the type-cast segment to only return users, selecting minimal properties
            $url = "/groups/$GroupId/transitiveMembers/microsoft.graph.user`?\$select=id,displayName,accountEnabled&`$count=true"
            $headers = @{ "ConsistencyLevel" = "eventual" }

            while ($true) {
                $resp = Invoke-MgGraphRequest -Method GET -Uri $url -Headers $headers -ErrorAction Stop
                if ($resp -and $resp.value) {
                    foreach ($u in $resp.value) {
                        $users.Add([PSCustomObject]@{
                            ObjectId       = $u.id
                            DisplayName    = $u.displayName
                            AccountEnabled = [bool]$u.accountEnabled
                        })
                    }
                }

                if ($resp.'@odata.nextLink') {
                    $url = $resp.'@odata.nextLink'
                } else {
                    break
                }
            }
            break
        }
        catch {
            $retryCount++
            if ($retryCount -ge $MaxRetries) {
                Write-LogMessage "Failed to get transitive users for group $GroupId after $MaxRetries attempts: $($_.Exception.Message)" "Error"
                break
            }
            Write-LogMessage "Retry $retryCount of $MaxRetries for group $GroupId" "Warning"
            Start-Sleep -Seconds (2 * $retryCount) # Exponential backoff
        }
    } while ($retryCount -lt $MaxRetries)

    return $users
}

function Get-GraphSecurityGroups {
    param(
        [int]$MaxRetries = 3
    )

    $allGroups = New-Object System.Collections.Generic.List[object]
    $retryCount = 0

    do {
        try {
            $url = "/groups`?$filter=securityEnabled eq true&`$select=id,displayName,createdDateTime,securityEnabled,mailEnabled,groupTypes,deletedDateTime,renewedDateTime&`$count=true&`$top=200"
            $headers = @{ "ConsistencyLevel" = "eventual" }

            while ($true) {
                $resp = Invoke-MgGraphRequest -Method GET -Uri $url -Headers $headers -ErrorAction Stop
                if ($resp -and $resp.value) {
                    foreach ($g in $resp.value) {
                        $allGroups.Add($g)
                    }
                }

                if ($resp.'@odata.nextLink') {
                    $url = $resp.'@odata.nextLink'
                } else {
                    break
                }
            }
            break
        }
        catch {
            $retryCount++
            if ($retryCount -ge $MaxRetries) {
                Write-LogMessage "Failed to retrieve Entra ID groups after $MaxRetries attempts: $($_.Exception.Message)" "Error"
                break
            }
            Write-LogMessage "Retry $retryCount of $MaxRetries for retrieving Entra ID groups" "Warning"
            Start-Sleep -Seconds (2 * $retryCount)
        }
    } while ($retryCount -lt $MaxRetries)

    return $allGroups
}

if (-not (Test-GraphConnectionAndConnect)) {
    Write-LogMessage "Skipping Entra ID analysis due to connection issues" "Warning"
    $aadResults = @()
} else {
    try {
        Write-LogMessage "Retrieving Entra ID security groups..." "Info"
        # Use REST-based retrieval for resilience and consistent paging
        $mgGroups = Get-GraphSecurityGroups
        if (-not $mgGroups -or $mgGroups.Count -eq 0) {
            Write-LogMessage "No Entra ID groups returned from REST path. Trying SDK fallback..." "Warning"
            try {
                $mgGroups = Get-MgGroup -All -ConsistencyLevel eventual -Filter "securityEnabled eq true" -ErrorAction Stop
            }
            catch {
                Write-LogMessage "SDK fallback failed: $($_.Exception.Message)" "Error"
                $mgGroups = @()
            }
        }
        
        if ($MaxGroups -gt 0 -and $mgGroups.Count -gt $MaxGroups) {
            $mgGroups = $mgGroups | Select-Object -First $MaxGroups
            Write-LogMessage "Limited to first $MaxGroups groups due to MaxGroups parameter" "Info"
        }
        
        $script:TotalGroups += $mgGroups.Count
        Write-LogMessage "Found $($mgGroups.Count) security groups to analyze" "Info"
    }
    catch {
        Write-LogMessage "Failed to retrieve Entra ID groups: $($_.Exception.Message)" "Error"
        $mgGroups = @()
    }
    
    $aadResults = @()
    $aadGroupCount = 0
    
    foreach ($group in $mgGroups) {
        $aadGroupCount++
        $script:ProcessedGroups++
        
        if ($ShowProgress) {
            $percentComplete = [math]::Round(($aadGroupCount / $mgGroups.Count) * 100, 1)
            Write-Progress -Activity "Analyzing Entra ID Groups" -Status "Processing $($group.DisplayName)" -PercentComplete $percentComplete
        }
        
        try {
            Write-LogMessage "Analyzing Entra ID group: $($group.DisplayName) ($aadGroupCount of $($mgGroups.Count))" "Info"
            
            $members = Get-GraphGroupTransitiveUsers -GroupId $group.Id
            # Deduplicate users by ObjectId (defensive)
            $uniqueMembers = $members | Sort-Object ObjectId -Unique
            $memberCount = ($uniqueMembers | Measure-Object).Count

            if ($memberCount -eq 0) {
                if ($IncludeEmptyGroups) {
                    $aadResults += [PSCustomObject]@{
                        Source        = "Entra ID"
                        GroupName     = $group.DisplayName
                        GroupIdOrDN   = $group.Id
                        TotalMembers  = 0
                        DisabledCount = 0
                        DisabledPct   = "N/A"
                        Status        = "Inactive (Empty)"
                        LastModified  = $group.LastModifiedDateTime
                        Created       = $group.CreatedDateTime
                    }
                }
                continue
            }

            $disabledMembers = $uniqueMembers | Where-Object { $_.AccountEnabled -eq $false }
            $disabledPercent = [math]::Round((($disabledMembers.Count / $memberCount) * 100), 2)

            if ($disabledPercent -ge $ThresholdPercent) {
                $aadResults += [PSCustomObject]@{
                    Source        = "Entra ID"
                    GroupName     = $group.DisplayName
                    GroupIdOrDN   = $group.Id
                    TotalMembers  = $memberCount
                    DisabledCount = $disabledMembers.Count
                    DisabledPct   = "$disabledPercent %"
                    Status        = "Inactive (Disabled ≥$ThresholdPercent%)"
                    LastModified  = $group.LastModifiedDateTime
                    Created       = $group.CreatedDateTime
                }
            }
        }
        catch {
            Write-LogMessage "Error processing Entra ID group $($group.DisplayName): $($_.Exception.Message)" "Error"
        }
    }
    
    Write-Progress -Activity "Analyzing Entra ID Groups" -Completed
    Write-LogMessage "Completed Entra ID analysis. Found $($aadResults.Count) groups meeting criteria" "Success"
}

# --- Export Results ---
Write-LogMessage "Compiling final report..." "Info"

$report = @()
if ($adResults)  { $report += $adResults }
if ($aadResults) { $report += $aadResults }

# Calculate summary statistics
$totalGroups = ($report | Measure-Object).Count
$adGroups = ($report | Where-Object { $_.Source -eq "Active Directory" } | Measure-Object).Count
$aadGroups = ($report | Where-Object { $_.Source -eq "Entra ID" } | Measure-Object).Count
$emptyGroups = ($report | Where-Object { $_.Status -eq "Inactive (Empty)" } | Measure-Object).Count
$disabledGroups = ($report | Where-Object { $_.Status -like "Inactive (Disabled*" } | Measure-Object).Count

$endTime = Get-Date
$duration = $endTime - $script:StartTime

# Display summary
Write-Host "`n" + "="*80 -ForegroundColor Cyan
Write-Host "GROUP ANALYSIS SUMMARY" -ForegroundColor Cyan
Write-Host "="*80 -ForegroundColor Cyan
Write-Host "Analysis completed in: $($duration.ToString('hh\:mm\:ss'))" -ForegroundColor White
Write-Host "Total groups processed: $($script:ProcessedGroups)" -ForegroundColor White
Write-Host "Groups meeting criteria: $totalGroups" -ForegroundColor White
Write-Host "  - Active Directory: $adGroups" -ForegroundColor Yellow
Write-Host "  - Entra ID: $aadGroups" -ForegroundColor Yellow
Write-Host "  - Empty groups: $emptyGroups" -ForegroundColor Red
Write-Host "  - Groups with ≥$ThresholdPercent% disabled members: $disabledGroups" -ForegroundColor Red
Write-Host "="*80 -ForegroundColor Cyan

if ($totalGroups -eq 0) {
    Write-LogMessage "No groups met the criteria." "Info"
} else {
    # Display detailed results
    Write-Host "`nDETAILED RESULTS:" -ForegroundColor Green
    $report | Sort-Object Source, GroupName | Format-Table -AutoSize
    
    # Export to CSV
    if ([string]::IsNullOrEmpty($ExportPath)) {
        $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
        $csvPath = Join-Path -Path (Get-Location) -ChildPath "GroupDisabledMembersReport_$timestamp.csv"
    } else {
        if (-not (Test-Path $ExportPath)) {
            New-Item -Path $ExportPath -ItemType Directory -Force | Out-Null
        }
        $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
        $csvPath = Join-Path -Path $ExportPath -ChildPath "GroupDisabledMembersReport_$timestamp.csv"
    }
    
    try {
        $report | Export-Csv $csvPath -NoTypeInformation -Encoding UTF8
        Write-LogMessage "Report exported to: $csvPath" "Success"
    }
    catch {
        Write-LogMessage "Failed to export CSV: $($_.Exception.Message)" "Error"
    }
    
    # Export summary to text file
    $summaryPath = $csvPath -replace '\.csv$', '_Summary.txt'
    $summaryContent = @"
Group Analysis Summary
Generated: $(Get-Date)
Duration: $($duration.ToString('hh\:mm\:ss'))
Threshold: $ThresholdPercent%

Statistics:
- Total groups processed: $($script:ProcessedGroups)
- Groups meeting criteria: $totalGroups
- Active Directory groups: $adGroups
- Entra ID groups: $aadGroups
- Empty groups: $emptyGroups
- Groups with ≥$ThresholdPercent% disabled members: $disabledGroups

Top 10 Groups by Disabled Percentage:
$($report | Where-Object { $_.DisabledPct -ne "N/A" } | Sort-Object { [double]($_.DisabledPct -replace ' %', '') } -Descending | Select-Object -First 10 | Format-Table -AutoSize | Out-String)
"@
    
    try {
        $summaryContent | Out-File -FilePath $summaryPath -Encoding UTF8
        Write-LogMessage "Summary exported to: $summaryPath" "Success"
    }
    catch {
        Write-LogMessage "Failed to export summary: $($_.Exception.Message)" "Error"
    }
}

Write-LogMessage "Script execution completed" "Success"