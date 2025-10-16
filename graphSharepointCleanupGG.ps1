# Set working paths
$usersCsvPath = "C:\temp\exportUsers_2025-5-21.csv"
$groupsCsvPath = "C:\temp\gggroups.csv"
$logPath = "C:\temp\RemoveUsersLog.txt"

# Prepare the log file
"Timestamp`tSiteUrl`tGroupName`tUserPrincipalName`tResult`tError" | Out-File -FilePath $logPath -Encoding UTF8

# Connect to Microsoft Graph first (this will help with permissions)
Connect-MgGraph -Scopes "GroupMember.ReadWrite.All", "Directory.Read.All", "Sites.ReadWrite.All"

# Connect to SharePoint Online
Connect-SPOService -Url "https://gianteagle-admin.sharepoint.com"

# Load conveyed users
$allUsers = Import-Csv $usersCsvPath
$conveyedUsers = $allUsers | Select-Object -ExpandProperty userPrincipalName

# Load SharePoint site/group mapping
$groupMappings = Import-Csv $groupsCsvPath

# Loop through mappings
foreach ($mapping in $groupMappings) {
    $siteUrl = $mapping.SiteUrl
    $groupName = $mapping.GroupName

    Write-Host "`nProcessing group: $groupName at $siteUrl" -ForegroundColor Cyan

    try {
        # Connect to the specific site
        Connect-PnPOnline -Url $siteUrl

        # Get the group
        $group = Get-PnPGroup -Identity $groupName

        if ($group) {
            foreach ($upn in $conveyedUsers) {
                $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
                try {
                    # Remove the user from the group
                    Remove-PnPUserFromGroup -LoginName $upn -GroupName $groupName
                    "$timestamp`t$siteUrl`t$groupName`t$upn`tRemoved`t" | Out-File -FilePath $logPath -Append
                    Write-Host "✅ Removed: $upn from '$groupName'" -ForegroundColor Green
                } catch {
                    "$timestamp`t$siteUrl`t$groupName`t$upn`tFailed`t$($_.Exception.Message)" | Out-File -FilePath $logPath -Append
                    Write-Warning "Could not remove $upn from '$groupName': $($_.Exception.Message)"
                }
            }
        } else {
            $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
            "$timestamp`t$siteUrl`t$groupName`t`tFailed`tGroup not found" | Out-File -FilePath $logPath -Append
            Write-Warning "Group not found: $groupName"
        }
    } catch {
        $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        "$timestamp`t$siteUrl`t$groupName`t`tFailed`t$($_.Exception.Message)" | Out-File -FilePath $logPath -Append
        Write-Warning "Error processing site $siteUrl : $($_.Exception.Message)"
    }
}

# Disconnect from services
Disconnect-MgGraph
Disconnect-SPOService

Write-Host "`nScript completed. Check the log file at: $logPath" -ForegroundColor Green 