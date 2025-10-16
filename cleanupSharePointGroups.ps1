# Set paths
$usersCsvPath = "C:\temp\exportUsers_2025-5-21.csv"
$groupsCsvPath = "C:\temp\gggroups.csv"
$logPath = "C:\temp\SharePointCleanup.log"

# Initialize log file
"Timestamp, Site URL, Group Name, User, Status, Error" | Out-File -FilePath $logPath -Encoding UTF8

# Load the data
$users = Import-Csv $usersCsvPath
$groupMappings = Import-Csv $groupsCsvPath

# Connect to SharePoint Admin Center
Write-Host "Connecting to SharePoint Admin Center..." -ForegroundColor Yellow
Connect-PnPOnline -Url "https://gianteagle-admin.sharepoint.com" -UseWebLogin

# Process each site and group
foreach ($mapping in $groupMappings) {
    $siteUrl = $mapping.SiteUrl
    $groupName = $mapping.GroupName

    Write-Host "`nProcessing site: $siteUrl" -ForegroundColor Cyan
    Write-Host "Group: $groupName" -ForegroundColor Cyan

    try {
        # Connect to the site
        Connect-PnPOnline -Url $siteUrl -UseWebLogin

        # Get the group
        $group = Get-PnPGroup -Identity $groupName

        if ($group) {
            # Process each user
            foreach ($user in $users) {
                $upn = $user.userPrincipalName
                $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

                try {
                    # Check if user is in the group
                    $groupMember = Get-PnPGroupMember -Identity $groupName | Where-Object { $_.Email -eq $upn }

                    if ($groupMember) {
                        # Remove user from group
                        Remove-PnPUserFromGroup -LoginName $upn -GroupName $groupName
                        "$timestamp, $siteUrl, $groupName, `${upn}`, Removed, " | Out-File -FilePath $logPath -Append
                        Write-Host "✅ Removed: ${upn}" -ForegroundColor Green
                    } else {
                        "$timestamp, $siteUrl, $groupName, `${upn}`, Not in group, " | Out-File -FilePath $logPath -Append
                        Write-Host "ℹ️ User not in group: ${upn}" -ForegroundColor Yellow
                    }
                } catch {
                    "$timestamp, $siteUrl, $groupName, `${upn}`, Failed, $($_.Exception.Message)" | Out-File -FilePath $logPath -Append
                    Write-Host "❌ Error removing ${upn}: $($_.Exception.Message)" -ForegroundColor Red
                }
            }
        } else {
            $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
            "$timestamp, $siteUrl, $groupName, , Group not found, " | Out-File -FilePath $logPath -Append
            Write-Host "❌ Group not found: $groupName" -ForegroundColor Red
        }
    } catch {
        $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        "$timestamp, $siteUrl, $groupName, , Site error, $($_.Exception.Message)" | Out-File -FilePath $logPath -Append
        Write-Host "❌ Error accessing site: $($_.Exception.Message)" -ForegroundColor Red
    }
}

Write-Host "`nScript completed. Check the log file at: $logPath" -ForegroundColor Green
