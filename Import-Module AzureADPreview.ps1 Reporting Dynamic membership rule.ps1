Import-Module AzureADPreview

$storeInfo = @{}
$keyCarrierGroups = @()
$DynamicGroupSet = @()

Function UpdateDynamicMembershipRule {
    foreach($store in $storeinfo.Keys){
        Set-AzureADMSGroup -Id $storeinfo.Item($store) -MembershipRule {membership rule goes here!!!!!!!}
    }
}

Function SearchADGroups {
    $keyCarrierGroups = Get-ADGroup -Filter {DisplayName -like "*_GetgoStoreLeadership"} 
    $keyCarrierGroups | export-csv -Path "C:\Users\914476\OneDrive - Giant Eagle, Inc\Documents\GitHub\_outfile\ADGroups.csv" -Force
}

Function buildSet {
    $groupInfo = Import-csv -Path "C:\Users\914476\OneDrive - Giant Eagle, Inc\Documents\GitHub\_outfile\ADGroups.csv"
    Foreach ($group in $keyCarrierGroups){$DynamicGroupSet += Get-AzureADMSGroup -Id $group.Name.Split("_")[1]}
    $DynamicGroupSet | export-csv -Path "C:\Users\914476\OneDrive - Giant Eagle, Inc\Documents\GitHub\_outfile\AzureADMSGroups.csv"
}

Function formatSet {
    #$groups = Import-Csv -Path C:\Users\914476\documents\github\_outfile\KeyCarriersADMSGroups.csv
    foreach($group in $DynamicGroupSet){
        $storeInfo.add($group.DisplayName.Split("_")[0],$group.Id)
    }
    #$storeInfo
}

SearchADGroups
buildSet
formatSet
#UpdateDynamicMembershipRule
Write-host "Done" -ForegroundColor Green