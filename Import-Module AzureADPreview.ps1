Import-Module AzureADPreview

$targetedGroups = @()
$storeInfo = @{}
$ExplicitAdditions = @()
$allAdditions = @()
$membershipRule = ''

$targetedGroups = (Get-ADGroup -filter {DisplayName -like "*_GetGoStoreLeadership"} -SearchBase "OU=O365,OU=Exchange,DC=corp,DC=gianteagle,DC=com") 
$DynamicGroupSet = foreach ($group in $targetedGroups){Get-AzureADMSGroup -Id $group.Name.Split("_")[1]}
foreach($group in $DynamicGroupSet){$storeInfo.add($group.DisplayName.Split("_")[0],$group.Id)}
foreach($store in $storeinfo.Keys){
    $membershipRule =  'membershipRule is here'#'user.Department -contains '+'"'+$store.ToString()+'"'+' -and user.extensionAttribute3 -eq "A" -and (user.extensionAttribute13 -In ["10010","80003","80011","80014","80066","80090","10136","10159","10181","10183","10185","70128","80177","80191"] or user.extensionAttribute6 -In ["10010","80003","80011","80014","80066","80090","10136","10159","10181","10183","10185","70128","80177","80191"] or user.extensionAttribute13 -In ["10012","10022","10023","10104","10123","70017","70029","70056","70099","80004","80016","80076","80143","80156","10166","10179","80178","80217","80224"] or user.extensionAttribute6 -In ["10012","10022","10023","10104","10123","70017","70029","70056","70099","80004","80016","80076","80143","80156","10166","10179","80178","80217","80224"] or user.extensionAttribute13 -In ["10005","10006","10013","10064","10070","10078","10146","00205","10158","10173","40057"] or user.extensionAttribute6 -In ["10005","10006","10013","10064","10070","10078","10146","00205","10158","10173","40057"])'
    #Set-AzureADMSGroup -Id ($storeinfo.Item($store)) -MembershipRule $membershipRule
    #Get-AzureADMSGroup -Id ($storeinfo.Item($store)) -MembershipRule $membershipRule
    #Get-AzureADMSGroup -Id 'b94d5bc5-5330-429d-8031-ac56e1a9e885' | fl
}
#$DynamicGroupSet.MembershipRule
#$ExplicitAdditionas = $DynamicGroupSet.MembershipRule.Split("\(")
#$ExplicitAdditionas
#Get-ADGroup -filter {DisplayName -like "*_GetGoStoreLeadership"} -SearchBase "OU=O365,OU=Exchange,DC=corp,DC=gianteagle,DC=com"
$Filters = $DynamicGroupSet.MembershipRule.Split('"') | Where-Object {$_ -match '^\d+$' -or $_ -match '^\w+([.]\w+)?@(corp[.])?gianteagle.com$'}
$ExplicitAdditions = @()
$Filters | ForEach-Object {
    if($_ -match '^\d+$') {
        Write-Host "Yes"
        #$ExplicitAdditionas += (Get-ADUser -Filter {extensionAttribute6 -like "*$_*"} -SearchBase 'OU=Retail Users FIM,OU=Users,OU=Managed Users & Computers,DC=corp,DC=gianteagle,DC=com').userPrincipleName
    } else {
        Write-Host "No"
       $ExplicitAdditions += $_ #(Get-ADUser -Filter {userPrincipleName -eq $_} -SearchBase 'OU=Retail Users FIM,OU=Users,OU=Managed Users & Computers,DC=corp,DC=gianteagle,DC=com').userPrincipleName
    }
}
foreach ($ExplicitAddition in $ExplicitAdditions){
    $allAdditions += " -or (userPrincipleName -eq "+$ExplicitAddition+")"
}
$membershipRule + $allAdditions
#$membershipRule = $membershipRule + $allAdditions
#Set-AzureADMSGroup -Id ($storeinfo.Item($store)) -MembershipRule $membershipRule 
