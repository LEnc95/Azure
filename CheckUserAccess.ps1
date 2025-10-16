# Import the SharePoint Online Management Shell module
Import-Module Microsoft.Online.SharePoint.PowerShell -DisableNameChecking

# Set paths
$usersCsvPath = "C:\temp\exportUsers_2025-5-21.csv"
$groupsCsvPath = "C:\temp\gggroups_corrected.csv"
$outputPath = "C:\temp\UserAccessCheck.csv"

# Initialize output file
"SiteUrl, User, HasDirectAccess, GroupsUserIsIn" | Out-File -FilePath $outputPath -Encoding UTF8

# Load the data
$users = Import-Csv $usersCsvPath
$groupMappings = Import-Csv $groupsCsvPath

# Connect to SharePoint Online Admin Center
Write-Host "Connecting to SharePoint Online Admin Center..." -ForegroundColor Yellow
Connect-SPOService -Url "https://gianteagle-admin.sharepoint.com"

# Get unique sites
$uniqueSites = $groupMappings | Select-Object -ExpandProperty SiteUrl -Unique

# Process each site
foreach ($siteUrl in $uniqueSites) {
    Write-Host "`nChecking site: $siteUrl" -ForegroundColor Cyan
    
    try {
        # Get all site users (direct access)
        $siteUsers = Get-SPOUser -Site $siteUrl
        
        # Get all groups and their members
        $allGroups = Get-SPOSiteGroup -Site $siteUrl
        $groupMemberships = @{}
        
        foreach ($group in $allGroups) {
            $groupMembers = Get-SPOUser -Site $siteUrl -Group $group.Title
            $groupMemberships[$group.Title] = $groupMembers
        }
        
        # Check each user from your CSV
        foreach ($user in $users) {
            $upn = $user.userPrincipalName
            $hasDirectAccess = $false
            $groupsUserIsIn = @()
            
            # Check for direct site access
            foreach ($siteUser in $siteUsers) {
                if ($siteUser.LoginName -eq $upn -or $siteUser.Email -eq $upn) {
                    $hasDirectAccess = $true
                    break
                }
            }
            
            # Check which groups the user is in
            foreach ($groupName in $groupMemberships.Keys) {
                $groupMembers = $groupMemberships[$groupName]
                foreach ($member in $groupMembers) {
                    if ($member.LoginName -eq $upn -or $member.Email -eq $upn) {
                        $groupsUserIsIn += $groupName
                        break
                    }
                }
            }
            
            $groupsString = $groupsUserIsIn -join "; "
            if ([string]::IsNullOrEmpty($groupsString)) {
                $groupsString = "None"
            }
            
            "$siteUrl, $upn, $hasDirectAccess, $groupsString" | Out-File -FilePath $outputPath -Append
            
            Write-Host ("User: " + $upn) -ForegroundColor White
            Write-Host ("  Direct Access: " + $hasDirectAccess) -ForegroundColor $(if($hasDirectAccess){"Green"}else{"Red"})
            Write-Host ("  Groups: " + $groupsString) -ForegroundColor $(if($groupsString -eq "None"){"Red"}else{"Green"})
        }
        
    } catch {
        Write-Host ("ERROR - Could not check site: " + $siteUrl + " - " + $_.Exception.Message) -ForegroundColor Red
    }
}

# Disconnect from SharePoint Online
Disconnect-SPOService

Write-Host "`nUser access check completed. Results saved to: $outputPath" -ForegroundColor Green 