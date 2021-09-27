<##########
### Title: Update Dynamic Group Membership
### Author: Luke Encrapera
### Email: Luke.Encrapera@GiantEagle.com
### Date: 9/24/2021
##########>

<#  USAGE:
    Update $targetedGroups and $filterRule before running 
    Comment out the Set-AzureADMSGroup in the $reportHash loop to report without setting anything
    All out files to C:\Temp\
#>

Import-Module AzureADPreview

#Init Vars
$targetedGroups = @()
$storeInfo = @{}
$reportHash = @{}
$out = @()
$adds = ""
$DateTime = Get-Date -f "yyyy-MM-dd HH-m" 
$reportLocations = "C:\Temp\DynamicGroupSet_$DateTime.csv","C:\Temp\reportHash_$DateTime.txt","C:\Temp\reportStores_$DateTime.txt","C:\Temp\reportAdds_$DateTime.txt","C:\Temp\whatIsSet_$DateTime.txt"

#Get Dynamic group/groups by display name and export data to "C:\Temp\DynamicGroupSet_"+$DateTime+".csv"
$targetedGroups = (Get-ADGroup -filter { DisplayName -like "*_GetGoKitchen" } -SearchBase "OU=O365,OU=Exchange,DC=corp,DC=gianteagle,DC=com") 
$DynamicGroupSet = foreach ($group in $targetedGroups) { Get-AzureADMSGroup -Id $group.Name.Split("_")[1] }
$DynamicGroupSet | Export-Csv -Path "C:\Temp\DynamicGroupSet_$DateTime.csv" -Force -NoTypeInformation
foreach ($group in $DynamicGroupSet) { $storeInfo.add($group.DisplayName.Split("_")[0], $group.Id) }
foreach ($store in $storeinfo.Keys) {
    $allAdditions = @()
    $ExplicitAdditions = @()
    $Filters = ($DynamicGroupSet | Where-Object { $_.displayName -match "^$store" }).MembershipRule.Split('"') | Where-Object { $_ -match '^\d+$' -or $_ -match '^\w+([.]\w+)?@(corp[.])?gianteagle.com$' }
    #Disect the membership rules and add additions to filter to $ExplicitAdditions
    $Filters | ForEach-Object { 
        if ($_ -match '^\d+$') {
        }
        else {
            $ExplicitAdditions += $_ 
        }
    }
    foreach ($ExplicitAddition in $ExplicitAdditions) {
        $allAdditions += " -or (user.userPrincipalname -eq " + '"' + $ExplicitAddition + '"' + ")"
    }
    $reportHash.Add($store, $allAdditions)
}
$reportedStores = $reportHash.Keys
$reportedAdds = $reportHash.Values
#Report to CSV file path C:\Temp\
$reportHash | Out-File -FilePath "C:\Temp\reportHash_$DateTime.txt" -Force 
$reportedStores[0] | Out-File -FilePath "C:\Temp\reportStores_$DateTime.txt" -Force 
$reportedAdds[0] | Out-File -FilePath "C:\Temp\reportAdds_$DateTime.txt" -Force
#Report and Update MembershipRules with new filter and append any prior additions.
$reportHash.Keys | foreach-object {
    $adds += " " + $reportHash["$_"]
    $filterRule = '(user.Department -contains ' + '"' + $_ + '")' + ' -and (user.extensionAttribute3 -eq "A") -and ((user.extensionAttribute13 -In ["10182","80105","80148","88063","80208","80209","80212","88065","98023"]) -or (user.extensionAttribute6 -contains "80105") -or (user.extensionAttribute6 -contains "80148") -or (user.extensionAttribute6 -contains "88063") -or (user.extensionAttribute6 -contains "80208") -or (user.extensionAttribute6 -contains "80209") -or (user.extensionAttribute6 -contains "80212") -or (user.extensionAttribute6 -contains "88065") -or (user.extensionAttribute6 -contains "98023"))' 
    $out += $filterRule + $adds
    $out | Out-File -FilePath "C:\Temp\whatIsSet_$DateTime.txt" 
    $filterRule = $filterRule + $adds
    Set-AzureADMSGroup -id $storeinfo["$_"] -membershipRule $filterRule
    $adds = $null
}
Write-Host "Complete" -ForegroundColor Yellow
$reportLocations | ForEach-Object {Write-Host "View report @ $_" -ForegroundColor Green}
