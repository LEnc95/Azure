# Set working paths
$usersCsvPath = "C:\temp\exportUsers_2025-5-21.csv"
$groupsCsvPath = "C:\temp\gggroups.csv"
$logPath = "C:\temp\RemoveUsersLog.txt"

# Check if required files exist
if (-not (Test-Path $usersCsvPath)) {
    Write-Error "Users CSV file not found at: $usersCsvPath"
    exit
}
if (-not (Test-Path $groupsCsvPath)) {
    Write-Error "Groups CSV file not found at: $groupsCsvPath"
    exit
}

# Add confirmation prompt
$confirmation = Read-Host "This will remove users from SharePoint groups. Are you sure you want to continue? (Y/N)"
if ($confirmation -ne 'Y') {
    Write-Host "Operation cancelled by user"
    exit
}

# Prepare the log file
"Timestamp`tSiteUrl`tGroupName`tUserPrincipalName`tResult`tError" | Out-File -FilePath $logPath -Encoding UTF8

# Load conveyed users
$allUsers = Import-Csv $usersCsvPath
$conveyedUsers = $allUsers | Select-Object -ExpandProperty userPrincipalName

# Load SharePoint site/group mapping
$groupMappings = Import-Csv $groupsCsvPath

# Loop through mappings
foreach ($mapping in $groupMappings) {
    $siteUrl = $mapping.SiteUrl
    $groupName = $mapping.GroupName

    Write-Host "`nConnecting to: $siteUrl ..." -ForegroundColor Cyan
    try {
        Connect-PnPOnline -Url $siteUrl -UseWebLogin
    } catch {
        $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        "$timestamp`t$siteUrl`t$groupName`t`tFailed`t$_" | Out-File -FilePath $logPath -Append
        continue
    }

    foreach ($upn in $conveyedUsers) {
        $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        try {
            Remove-PnPUserFromGroup -LoginName $upn -Group $groupName -ErrorAction Stop
            "$timestamp`t$siteUrl`t$groupName`t$upn`tRemoved`t" | Out-File -FilePath $logPath -Append
            Write-Host "✅ Removed: $upn from '$groupName' at $siteUrl"
        } catch {
            "$timestamp`t$siteUrl`t$groupName`t$upn`tFailed`t$($_.Exception.Message)" | Out-File -FilePath $logPath -Append
            Write-Warning "Could not remove $upn from '$groupName' at $siteUrl - Error: $($_.Exception.Message)"
        }
    }
    
    # Disconnect from the current site
    Disconnect-PnPOnline
}

Write-Host "`nScript completed. Check the log file at: $logPath" -ForegroundColor Green
