<##########
### Title: Update Dynamic Group Membership
### Author: Luke Encrapera
### Email: Luke.Encrapera@GiantEagle.com
### Date: 9/24/2021
##########>

<#  USAGE:
    Update $targetedGroups and $filterRule before running 
    Comment out the Set-AzureADMSGroup in the $reportHash loop to report without setting
    All out files to C:\Temp\
#>

Import-Module AzureADPreview

#Init Vars
$targetedGroups = @()
$storeInfo = @{}
$reportHash = @{}
$out = @()
$adds = ""
$reportLocations = "C:\Temp\reportHash.txt","C:\Temp\reportStores.txt","C:\Temp\reportAdds.txt","C:\Temp\whatIsSet.txt"

#Get Dynamic group/groups by display name and export data to C:\Temp\DynamicGroupSet.csv
$targetedGroups = (Get-ADGroup -filter { DisplayName -like "*_GetGoStoreLeadership" } -SearchBase "OU=O365,OU=Exchange,DC=corp,DC=gianteagle,DC=com") 
$DynamicGroupSet = foreach ($group in $targetedGroups) { Get-AzureADMSGroup -Id $group.Name.Split("_")[1] }
$DynamicGroupSet | Export-Csv -Path C:\Temp\DynamicGroupSet.csv -Force -NoTypeInformation
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
$reportHash | Out-File -FilePath C:\Temp\reportHash.txt -Force 
$reportedStores[0] | Out-File -FilePath C:\Temp\reportStores.txt -Force 
$reportedAdds[0] | Out-File -FilePath C:\Temp\reportAdds.txt
#Report and Update MembershipRules with new filter and append any prior additions.
$reportHash.Keys | foreach-object {
    $adds += " " + $reportHash["$_"]
    $filterRule = '(user.Department -contains ' + '"' + $_ + '")' + '-and (user.extensionAttribute3 -eq "A") -and ((user.extensionAttribute13 -In ["10041","10046","10060","10061","10062","10080","10084","10085","10086","10087","10105","10140","10141","10143","10144","10145","10168","10169","10174","10176","10177","10178","10182","21083","80047","80123","80207","80215","80225","80232"]) -or (user.extensionAttribute6 -contains "10041") -or (user.extensionAttribute6 -contains "10046") -or (user.extensionAttribute6 -contains "10060") -or (user.extensionAttribute6 -contains "10061") -or (user.extensionAttribute6 -contains "10062") -or (user.extensionAttribute6 -contains "10080") -or (user.extensionAttribute6 -contains "10084") -or (user.extensionAttribute6 -contains "10085") -or (user.extensionAttribute6 -contains "10086") -or (user.extensionAttribute6 -contains "10087") -or (user.extensionAttribute6 -contains "10105") -or (user.extensionAttribute6 -contains "10140") -or (user.extensionAttribute6 -contains "10141") -or (user.extensionAttribute6 -contains "10143") -or (user.extensionAttribute6 -contains "10144") -or (user.extensionAttribute6 -contains "10145") -or (user.extensionAttribute6 -contains "10168") -or (user.extensionAttribute6 -contains "10169") -or (user.extensionAttribute6 -contains "10174") -or (user.extensionAttribute6 -contains "10176") -or (user.extensionAttribute6 -contains "10177") -or (user.extensionAttribute6 -contains "10178") -or (user.extensionAttribute6 -contains "21083") -or (user.extensionAttribute6 -contains "80047") -or (user.extensionAttribute6 -contains "80123") -or (user.extensionAttribute6 -contains "80207") -or (user.extensionAttribute6 -contains "80215") -or (user.extensionAttribute6 -contains "80225"))' 
    $out += $filterRule + $adds
    $out | Out-File -FilePath C:\Temp\whatIsSet.txt 
    $filterRule = $filterRule + $adds
    #Set-AzureADMSGroup -id $storeinfo["$_"] -membershipRule $filterRule
    $adds = $null
}
Write-Host "Complete" -ForegroundColor Yellow
$reportLocations | ForEach-Object {Write-Host "View report @ $_" -ForegroundColor Green}
