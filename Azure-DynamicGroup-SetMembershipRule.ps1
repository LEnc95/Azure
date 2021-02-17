#(user.Department -contains "6513") -and (user.extensionAttribute3 -eq "A") -and ((user.extensionAttribute13 -In ["10010","80003","80011","80014","80066","80090","10136","10159","10181","10183","10185","70128","80177","80191"]) -or (user.extensionAttribute6 -contains "10010") -or (user.extensionAttribute6 -contains "80003") -or (user.extensionAttribute6 -contains "80011") -or (user.extensionAttribute6 -contains "80014") -or (user.extensionAttribute6 -contains "80066") -or (user.extensionAttribute6 -contains "80090") -or (user.extensionAttribute6 -contains "10136") -or (user.extensionAttribute6 -contains "10159") -or (user.extensionAttribute6 -contains "10181") -or (user.extensionAttribute6 -contains "10183") -or (user.extensionAttribute6 -contains "10185") -or (user.extensionAttribute6 -contains "70128") -or (user.extensionAttribute6 -contains "80177") -or (user.extensionAttribute6 -contains "80191")) #FrontEnd
#(user.Department -contains "6513") -and (user.extensionAttribute3 -eq "A") -and ((user.extensionAttribute13 -In ["10012","10022","10023","10104","10123","70017","70029","70056","70099","80004","80016","80076","80143","80156","10166","10179","80178","80217","80224"]) -or (user.extensionAttribute6 -contains "10012") -or (user.extensionAttribute6 -contains "10022") -or (user.extensionAttribute6 -contains "10023") -or (user.extensionAttribute6 -contains "10104") -or (user.extensionAttribute6 -contains "10123") -or (user.extensionAttribute6 -contains "70017") -or (user.extensionAttribute6 -contains "70029") -or (user.extensionAttribute6 -contains "70056") -or (user.extensionAttribute6 -contains "70099") -or (user.extensionAttribute6 -contains "80004") -or (user.extensionAttribute6 -contains "80016") -or (user.extensionAttribute6 -contains "80076") -or (user.extensionAttribute6 -contains "80143") -or (user.extensionAttribute6 -contains "80156") -or (user.extensionAttribute6 -contains "10166") -or (user.extensionAttribute6 -contains "10179") -or (user.extensionAttribute6 -contains "80178") -or (user.extensionAttribute6 -contains "80217") -or (user.extensionAttribute6 -contains "80224"))#Grocery
#(user.Department -contains "6513") -and (user.extensionAttribute3 -eq "A") -and ((user.extensionAttribute13 -In ["10005","10006","10013","10064","10070","10078","10146","205","10158","10173","40057"]) -or (user.extensionAttribute6 -contains "10005") -or (user.extensionAttribute6 -contains "10006") -or (user.extensionAttribute6 -contains "10013") -or (user.extensionAttribute6 -contains "10064") -or (user.extensionAttribute6 -contains "10070") -or (user.extensionAttribute6 -contains "10078") -or (user.extensionAttribute6 -contains "10146") -or (user.extensionAttribute6 -contains "205") -or (user.extensionAttribute6 -contains "10158") -or (user.extensionAttribute6 -contains "10173") -or (user.extensionAttribute6 -contains "40057")) #StoreLeadership
#Current Dynamic Rule: (user.Department -contains "0002") -and (user.extensionAttribute3 -eq "A") -and ((user.extensionAttribute13 -In ["10005","10010","10012","10013","10023","70099","80003","80004"]) -or (user.extensionAttribute6 -contains "10005") -or (user.extensionAttribute6 -contains "10010") -or (user.extensionAttribute6 -contains "10012") -or (user.extensionAttribute6 -contains "10013") -or (user.extensionAttribute6 -contains "10023") -or (user.extensionAttribute6 -contains "70099") -or (user.extensionAttribute6 -contains "80003") -or (user.extensionAttribute6 -contains "80004"))
#Updated Rule: (user.Department -contains $store) -and (user.extensionAttribute3 -eq "A") -and (user.extensionAttribute6 -contains "10005") -or (user.extensionAttribute6 -contains "10006") -or (user.extensionAttribute6 -contains "10013") -or (user.extensionAttribute6 -contains "10064") -or (user.extensionAttribute6 -contains "10070") -or (user.extensionAttribute6 -contains "10078") -or (user.extensionAttribute6 -contains "10146") -or (user.extensionAttribute6 -contains "205") -or (user.extensionAttribute6 -contains "10158") -or (user.extensionAttribute6 -contains "10173") -or (user.extensionAttribute6 -contains "40057") -or (user.extensionAttribute6 -contains "10012") -or (user.extensionAttribute6 -contains "10022") -or (user.extensionAttribute6 -contains "10023") -or (user.extensionAttribute6 -contains "10104") -or (user.extensionAttribute6 -contains "10123") -or (user.extensionAttribute6 -contains "70017") -or (user.extensionAttribute6 -contains "70029") -or (user.extensionAttribute6 -contains "70056") -or (user.extensionAttribute6 -contains "70099") -or (user.extensionAttribute6 -contains "80004") -or (user.extensionAttribute6 -contains "80016") -or (user.extensionAttribute6 -contains "80076") -or (user.extensionAttribute6 -contains "80143") -or (user.extensionAttribute6 -contains "80156") -or (user.extensionAttribute6 -contains "10166") -or (user.extensionAttribute6 -contains "10179") -or (user.extensionAttribute6 -contains "80178") -or (user.extensionAttribute6 -contains "80217") -or (user.extensionAttribute6 -contains "80224") -or (user.extensionAttribute6 -contains "10010") -or (user.extensionAttribute6 -contains "80003") -or (user.extensionAttribute6 -contains "80011") -or (user.extensionAttribute6 -contains "80014") -or (user.extensionAttribute6 -contains "80066") -or (user.extensionAttribute6 -contains "80090") -or (user.extensionAttribute6 -contains "10136") -or (user.extensionAttribute6 -contains "10159") -or (user.extensionAttribute6 -contains "10181") -or (user.extensionAttribute6 -contains "10183") -or (user.extensionAttribute6 -contains "10185") -or (user.extensionAttribute6 -contains "70128") -or (user.extensionAttribute6 -contains "80177") -or (user.extensionAttribute6 -contains "80191")
#Bradons Filter
<#
(user.Department -contains "0018") -and (user.extensionAttribute3 -eq "A") 
-and        (
(user.extensionAttribute13 -In ["10010", "80003", "80011", "80014", "80066", "80090”, “10136”, “10159”, “10181”, “10183”, “10185”, “70128”, “80177”, “80191”, “10012”, “10022”, “10023”, “10104”, “10123”, “70017”, “70029”, “70056”, “70099”, “80004”, “80016”, “80076”, “80143”, “80156”, “10166”, “10179”, “80178”, “80217”, “80224”, “10005”, “10006”, “10013”, “10064”, “10070”, “10078”, “10146”, “205”, “10158”, “10173”, “40057"]) 

-or 

(user.extensionAttribute6 -In ["10010”, “80003”, “80011”, “80014”, “80066”, “80090”, “10136”, “10159”, “10181”, “10183”, “10185”, “70128”, “80177”, “80191”, “10012”, “10022”, “10023”, “10104”, “10123”, “70017”, “70029”, “70056”, “70099”, “80004”, “80016”, “80076”, “80143”, “80156”, “10166”, “10179”, “80178”, “80217”, “80224”, “10005”, “10006”, “10013”, “10064”, “10070”, “10078”, “10146”, “205”, “10158”, “10173”, “40057"])
)
#>
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
    $keyCarrierGroups = Get-ADGroup -Filter {DisplayName -like "0002_Key_Carriers"} 
    #$keyCarrierGroups | export-csv -Path C:\Users\914476\documents\github\_outfile\KeyCarriersGroups.csv -Force
}

Function buildSet {
    #$groupInfo = Import-csv -Path C:\Users\914476\documents\github\_outfile\KeyCarriersGroups.csv
    Foreach ($group in $keyCarrierGroups){$DynamicGroupSet += Get-AzureADMSGroup -Id $group.Name.Split("_")[1]}
    #$DynamicGroupSet | export-csv -Path C:\Users\914476\documents\github\_outfile\KeyCarriersADMSGroups.csv
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
UpdateDynamicMembershipRule
Write-host "Done" -ForegroundColor Green