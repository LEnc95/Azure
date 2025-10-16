# Import the SharePoint Online Management Shell module
Import-Module Microsoft.Online.SharePoint.PowerShell -DisableNameChecking

# Set paths
$usersCsvPath = "C:\temp\exportUsers_2025-5-21.csv"
$groupsCsvPath = "C:\temp\gggroups_corrected.csv"
$logPath = "C:\temp\SPOCleanup.log"

# Initialize log file
"Timestamp, Site URL, Group Name, User, Status, Error" | Out-File -FilePath $logPath -Encoding UTF8

# Load the data
$users = Import-Csv $usersCsvPath
$groupMappings = Import-Csv $groupsCsvPath

# Connect to SharePoint Online Admin Center
Write-Host "Connecting to SharePoint Online Admin Center..." -ForegroundColor Yellow
Connect-SPOService -Url "https://gianteagle-admin.sharepoint.com"

# Process each site and group
foreach ($mapping in $groupMappings) {
    $siteUrl = $mapping.SiteUrl
    $groupName = $mapping.GroupName

    Write-Host "Processing site: $siteUrl" -ForegroundColor Cyan
    Write-Host "Group: $groupName" -ForegroundColor Cyan

    foreach ($user in $users) {
        $upn = $user.userPrincipalName
        $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

        try {
            # Remove the user from the group
            Remove-SPOUser -Site $siteUrl -LoginName $upn -Group $groupName
            "$timestamp, $siteUrl, $groupName, $upn, Removed, " | Out-File -FilePath $logPath -Append
            Write-Host ("SUCCESS - Removed: " + $upn) -ForegroundColor Green
        } catch {
            "$timestamp, $siteUrl, $groupName, $upn, Failed, $($_.Exception.Message)" | Out-File -FilePath $logPath -Append
            Write-Host ("ERROR - Failed to remove " + $upn + ": " + $_.Exception.Message) -ForegroundColor Red
        }
    }
}

# Disconnect from SharePoint Online
Disconnect-SPOService

Write-Host "`nScript completed. Check the log file at: $logPath" -ForegroundColor Green

Write-Host "NOTE: Users have been removed from specific groups in the sites." -ForegroundColor Yellow
