Import-Module AzureADPreview

$keyCarrierGroups = @()
$storeInfo = @{}

$keyCarrierGroups = (Get-ADGroup -Filter {DisplayName -like "*_Key_Carriers"})
$DynamicGroupSet = foreach ($group in $keyCarrierGroups){Get-AzureADMSGroup -Id $group.Name.Split("_")[1]}
foreach($group in $DynamicGroupSet){$storeInfo.add($group.DisplayName.Split("_")[0],$group.Id)}
foreach($store in $storeinfo.Keys){
$membershipRule =  'user.Department -contains '+'"'+$store.ToString()+'"'+' -and user.extensionAttribute3 -eq "A" -and (user.extensionAttribute13 -In ["10010","80003","80011","80014","80066","80090","10136","10159","10181","10183","10185","70128","80177","80191"] or user.extensionAttribute6 -In ["10010","80003","80011","80014","80066","80090","10136","10159","10181","10183","10185","70128","80177","80191"] or user.extensionAttribute13 -In ["10012","10022","10023","10104","10123","70017","70029","70056","70099","80004","80016","80076","80143","80156","10166","10179","80178","80217","80224"] or user.extensionAttribute6 -In ["10012","10022","10023","10104","10123","70017","70029","70056","70099","80004","80016","80076","80143","80156","10166","10179","80178","80217","80224"] or user.extensionAttribute13 -In ["10005","10006","10013","10064","10070","10078","10146","00205","10158","10173","40057"] or user.extensionAttribute6 -In ["10005","10006","10013","10064","10070","10078","10146","00205","10158","10173","40057"])'
Set-AzureADMSGroup -Id ($storeinfo.Item($store)) -MembershipRule $membershipRule
}
