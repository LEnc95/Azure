# Import the SharePoint Online Management Shell module
Import-Module Microsoft.Online.SharePoint.PowerShell -DisableNameChecking

# Set paths
$usersCsvPath = "C:\temp\exportUsers_2025-5-21.csv"
$groupsCsvPath = "C:\temp\gggroups_corrected.csv"
$outputPath = "C:\temp\GroupMembershipCheck.csv"

# Initialize output file
"SiteUrl, GroupName, User, IsInGroup" | Out-File -FilePath $outputPath -Encoding UTF8

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

    Write-Host "`nChecking group membership for: $groupName at $siteUrl" -ForegroundColor Cyan

    try {
        # Get all members of the group
        $groupMembers = Get-SPOSiteGroup -Site $siteUrl -Group $groupName | Get-SPOUser -Site $siteUrl
        
        foreach ($user in $users) {
            $upn = $user.userPrincipalName
            $isInGroup = $false
            
            # Check if user is in the group
            foreach ($member in $groupMembers) {
                if ($member.LoginName -eq $upn -or $member.Email -eq $upn) {
                    $isInGroup = $true
                    break
                }
            }
            
            "$siteUrl, $groupName, $upn, $isInGroup" | Out-File -FilePath $outputPath -Append
            
            if ($isInGroup) {
                Write-Host ("FOUND - User in group: " + $upn) -ForegroundColor Green
            } else {
                Write-Host ("NOT FOUND - User not in group: " + $upn) -ForegroundColor Yellow
            }
        }
    } catch {
        Write-Host ("ERROR - Could not check group: " + $groupName + " - " + $_.Exception.Message) -ForegroundColor Red
    }
}

# Disconnect from SharePoint Online
Disconnect-SPOService

Write-Host "`nGroup membership check completed. Results saved to: $outputPath" -ForegroundColor Green 