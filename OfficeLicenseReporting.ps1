$AzureLicensesSkuInfo = Get-AzureADSubscribedSku | Select -Property Sku*,ConsumedUnits -ExpandProperty PrepaidUnits
$msolLicenseSkuInfo = Get-MsolAccountSku
# To view the list of all user accounts in your organization that have NOT been assigned any of your licensing plans (unlicensed users), run the following command:
Get-AzureAdUser | ForEach{ $licensed=$False ; For ($i=0; $i -le ($_.AssignedLicenses | Measure).Count ; $i++) { If( [string]::IsNullOrEmpty(  $_.AssignedLicenses[$i].SkuId ) -ne $True) { $licensed=$true } } ; If( $licensed -eq $false) { Write-Host $_.UserPrincipalName} }
# To view the list of all user accounts in your organization that have been assigned any of your licensing plans (licensed users), run the following command:
Get-AzureAdUser | ForEach { $licensed=$False ; For ($i=0; $i -le ($_.AssignedLicenses | Measure).Count ; $i++) { If( [string]::IsNullOrEmpty(  $_.AssignedLicenses[$i].SkuId ) -ne $True) { $licensed=$true } } ; If( $licensed -eq $true) { Write-Host $_.UserPrincipalName} }
# To list all of the users in your subscription, use the Get-AzureAdUser -All $true command.
<#Get-MsolUser -All#>
<#Get-MsolUser -All -UnlicensedUsersOnly#>
# To view the list of all licensed user accounts in your organization, run the following command:
Get-MsolUser -All | where {$_.isLicensed -eq $true}
# Use these commands to list the licenses that are assigned to a user account.
$userUPN="<user account UPN, such as belindan@contoso.com>"
$licensePlanList = Get-AzureADSubscribedSku
$userList = Get-AzureADUser -ObjectID $userUPN | Select -ExpandProperty AssignedLicenses | Select SkuID 
$userList | ForEach { $sku=$_.SkuId ; $licensePlanList | ForEach { If ( $sku -eq $_.ObjectId.substring($_.ObjectId.length - 36, 36) ) { Write-Host $_.SkuPartNumber } } }

# MSOL get users license skus and services
$msolUserSkus = (Get-MsolUser -UserPrincipalName belindan@litwareinc.com).Licenses
$msolUserServices = (Get-MsolUser -UserPrincipalName belindan@litwareinc.com).Licenses.ServiceStatus



#####
$users = @('luke.encrapera@gianteagle.com', '1220069@gianteagle.com')

foreach($user in $users){
$license = Get-MsolUser -UserPrincipalName $user.Licenses | Where-Object {$_.AccountSkuID -eq "gianteagle:SPE_F1" -or $_.AccountSkuID -eq "gianteagle:DESKLESSPACK"}
    If($license-ne $null){
        $groups = $license.GroupsAssigningLicense
        foreach($group in $groups){
            $group.Guid
        }

    }
    else{}
}