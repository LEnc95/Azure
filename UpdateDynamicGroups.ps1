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
$targetedGroups = (Get-ADGroup -filter { DisplayName -like "*_WetGo" } -SearchBase "OU=O365,OU=Exchange,DC=corp,DC=gianteagle,DC=com") 
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
    $filterRule = '(user.Department -contains ' + '"' + $_ + '")' + ' -and (user.extensionAttribute3 -eq "A") -and ((user.extensionAttribute13 -In ["80098","80121","80109","80210","80216","88033","10190","10191","80227","80239"]) -or (user.extensionAttribute6 -contains "80098") -or (user.extensionAttribute6 -contains "80121") -or (user.extensionAttribute6 -contains "80109") -or (user.extensionAttribute6 -contains "80210") -or (user.extensionAttribute6 -contains "80216") -or (user.extensionAttribute6 -contains "88033") -or (user.extensionAttribute6 -contains "10190") -or (user.extensionAttribute6 -contains "10191") -or (user.extensionAttribute6 -contains "80227") -or (user.extensionAttribute6 -contains "80239"))'
    $out += $filterRule + $adds
    $out | Out-File -FilePath "C:\Temp\whatIsSet_$DateTime.txt" 
    $filterRule = $filterRule + $adds
    Set-AzureADMSGroup -id $storeinfo["$_"] -membershipRule $filterRule
    $adds = $null
}
Write-Host "Complete" -ForegroundColor Yellow
$reportLocations | ForEach-Object {Write-Host "View report @ $_" -ForegroundColor Green}

<# Filter Example #>
<#
'(user.Department -contains ' + '"' + $_ + '")' + ' -and (user.extensionAttribute3 -eq "A") -and ((user.extensionAttribute13 -In ["10182","80105","80148","88063","80208","80209","80212","88065","98023"]) -or (user.extensionAttribute6 -contains "80105") -or (user.extensionAttribute6 -contains "80148") -or (user.extensionAttribute6 -contains "88063") -or (user.extensionAttribute6 -contains "80208") -or (user.extensionAttribute6 -contains "80209") -or (user.extensionAttribute6 -contains "80212") -or (user.extensionAttribute6 -contains "88065") -or (user.extensionAttribute6 -contains "98023"))'

*_GetGoStoreLeadership | Add ("10173","10189","10190","10191","10193","10197","10198","80228")
(user.Department -contains ' + '"' + $_ + '")' + ' -and (user.extensionAttribute3 -eq "A") -and ((user.extensionAttribute13 -In ["10041","10046","10060","10061","10062","10080","10084","10085","10086","10087","10105","10140","10141","10143","10144","10145","10168","10169","10174","10176","10177","10178","10182","21083","80047","80123","80207","80215","80225","80232","10173","10189","10190","10191","10193","10197","10198","80228"]) -or (user.extensionAttribute6 -contains "10041") -or (user.extensionAttribute6 -contains "10046") -or (user.extensionAttribute6 -contains "10060") -or (user.extensionAttribute6 -contains "10061") -or (user.extensionAttribute6 -contains "10062") -or (user.extensionAttribute6 -contains "10080") -or (user.extensionAttribute6 -contains "10084") -or (user.extensionAttribute6 -contains "10085") -or (user.extensionAttribute6 -contains "10086") -or (user.extensionAttribute6 -contains "10087") -or (user.extensionAttribute6 -contains "10105") -or (user.extensionAttribute6 -contains "10140") -or (user.extensionAttribute6 -contains "10141") -or (user.extensionAttribute6 -contains "10143") -or (user.extensionAttribute6 -contains "10144") -or (user.extensionAttribute6 -contains "10145") -or (user.extensionAttribute6 -contains "10168") -or (user.extensionAttribute6 -contains "10169") -or (user.extensionAttribute6 -contains "10174") -or (user.extensionAttribute6 -contains "10176") -or (user.extensionAttribute6 -contains "10177") -or (user.extensionAttribute6 -contains "10178") -or (user.extensionAttribute6 -contains "21083") -or (user.extensionAttribute6 -contains "80047") -or (user.extensionAttribute6 -contains "80123") -or (user.extensionAttribute6 -contains "80207") -or (user.extensionAttribute6 -contains "80215") -or (user.extensionAttribute6 -contains "80225") -or (user.extensionAttribute6 -contains "10173") -or (user.extensionAttribute6 -contains "10189") -or (user.extensionAttribute6 -contains "10190") -or (user.extensionAttribute6 -contains "10191") -or (user.extensionAttribute6 -contains "10193") -or (user.extensionAttribute6 -contains "10197") -or (user.extensionAttribute6 -contains "10198") -or (user.extensionAttribute6 -contains "80228"))

*_GetGoKitchen | Add (80228)
(user.Department -contains ' + '"' + $_ + '")' + ' -and (user.extensionAttribute3 -eq "A") -and ((user.extensionAttribute13 -In ["10182","80105","80148","88063","80208","80209","80212","88065","98023","80228"]) -or (user.extensionAttribute6 -contains "80105") -or (user.extensionAttribute6 -contains "80148") -or (user.extensionAttribute6 -contains "88063") -or (user.extensionAttribute6 -contains "80208") -or (user.extensionAttribute6 -contains "80209") -or (user.extensionAttribute6 -contains "80212") -or (user.extensionAttribute6 -contains "88065") -or (user.extensionAttribute6 -contains "98023") -or (user.extensionAttribute6 -contains "80228"))

*_GetGoCrew | Add ("80104","80180","80047","80048","80123","80210","80216")
(user.Department -contains ' + '"' + $_ + '")' + ' -and (user.extensionAttribute3 -eq "A") -and ((user.extensionAttribute13 -In ["21083","80104","80180","88063","80104","80180","80047","80048","80123","80210","80216") -or (user.extensionAttribute6 -contains "21083") -or (user.extensionAttribute6 -contains "80104") -or (user.extensionAttribute6 -contains "80180") -or (user.extensionAttribute6 -contains "88063") -or (user.extensionAttribute6 -contains "80047") -or (user.extensionAttribute6 -contains "80048") -or (user.extensionAttribute6 -contains "80123") -or (user.extensionAttribute6 -contains "80210") -or (user.extensionAttribute6 -contains "80216"))

*_WetGo | Add ("10190","10191","80227","80239")
(user.Department -contains ' + '"' + $_ + '")' + ' -and (user.extensionAttribute3 -eq "A") -and ((user.extensionAttribute13 -In ["80098","80121","80109","80210","80216","88033","10190","10191","80227","80239"]) -or (user.extensionAttribute6 -contains "80098") -or (user.extensionAttribute6 -contains "80121") -or (user.extensionAttribute6 -contains "80109") -or (user.extensionAttribute6 -contains "80210") -or (user.extensionAttribute6 -contains "80216") -or (user.extensionAttribute6 -contains "88033") -or (user.extensionAttribute6 -contains "10190") -or (user.extensionAttribute6 -contains "10191") -or (user.extensionAttribute6 -contains "80227") -or (user.extensionAttribute6 -contains "80239"))
#>