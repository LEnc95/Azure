# Import the SharePoint Online Management Shell module
Import-Module Microsoft.Online.SharePoint.PowerShell -DisableNameChecking

# Path to your groups CSV
$groupsCsvPath = "C:\temp\gggroups.csv"
$outputPath = "C:\temp\AllSiteGroups.csv"

# Load unique site URLs
$groupMappings = Import-Csv $groupsCsvPath
$uniqueSites = $groupMappings | Select-Object -ExpandProperty SiteUrl -Unique

# Connect to SharePoint Online Admin Center
Connect-SPOService -Url "https://gianteagle-admin.sharepoint.com"

$allGroups = @()
foreach ($siteUrl in $uniqueSites) {
    Write-Host "Listing groups for $siteUrl" -ForegroundColor Cyan
    try {
        $groups = Get-SPOSiteGroup -Site $siteUrl
        foreach ($group in $groups) {
            $allGroups += [PSCustomObject]@{
                SiteUrl = $siteUrl
                GroupName = $group.Title
            }
        }
    } catch {
        Write-Host ("ERROR - Could not list groups for " + $siteUrl + ": " + $_.Exception.Message) -ForegroundColor Red
    }
}

$allGroups | Export-Csv -Path $outputPath -NoTypeInformation -Encoding UTF8
Write-Host "All site groups have been exported to $outputPath" -ForegroundColor Green 