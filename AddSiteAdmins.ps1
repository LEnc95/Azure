# Import the SharePoint Online Management Shell module
Import-Module Microsoft.Online.SharePoint.PowerShell -DisableNameChecking

# Path to your groups CSV
$groupsCsvPath = "C:\temp\gggroups.csv"
$myLogin = "luke.encrapera@gianteagle.com"

# Load unique site URLs
$groupMappings = Import-Csv $groupsCsvPath
$uniqueSites = $groupMappings | Select-Object -ExpandProperty SiteUrl -Unique

# Connect to SharePoint Online Admin Center
Connect-SPOService -Url "https://gianteagle-admin.sharepoint.com"

foreach ($siteUrl in $uniqueSites) {
    Write-Host "Adding yourself as site collection admin to $siteUrl" -ForegroundColor Cyan
    Set-SPOUser -Site $siteUrl -LoginName $myLogin -IsSiteCollectionAdmin $true
}
Write-Host "Done! You are now site collection admin on all target sites." -ForegroundColor Green 