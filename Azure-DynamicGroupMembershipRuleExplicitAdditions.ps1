Import-Module AzureADPreview

<#
try { 
    $var = Get-AzureADTenantDetail 
} 
catch [Microsoft.Open.Azure.AD.CommonLibrary.AadNeedAuthenticationException] { 
    Write-Host "You're not connected to AzureAD"; 
    Write-Host "Make sure you have AzureAD mudule available on this system then use Connect-AzureAD to establish connection"; 
    $Credential = Get-Credential
    Connect-AzureAD -Credential $Credential
}
#>

$targetedGroups = @()
$storeInfo = @{}
$ExplicitAdditions = @()
$x = 0
$reportHash = @{}
$out = @()

$targetedGroups = (Get-ADGroup -filter { DisplayName -like "*_GetGoStoreLeadership" } -SearchBase "OU=O365,OU=Exchange,DC=corp,DC=gianteagle,DC=com") 
$DynamicGroupSet = foreach ($group in $targetedGroups) { Get-AzureADMSGroup -Id $group.Name.Split("_")[1] }
foreach ($group in $DynamicGroupSet) { $storeInfo.add($group.DisplayName.Split("_")[0], $group.Id) }
foreach ($store in $storeinfo.Keys) {
    $allAdditions = @()
    $ExplicitAdditions = @()
    $Filters = $DynamicGroupSet[$x].MembershipRule.Split('"') | Where-Object { $_ -match '^\d+$' -or $_ -match '^\w+([.]\w+)?@(corp[.])?gianteagle.com$' }
    $Filters | ForEach-Object {
        if ($_ -match '^\d+$') {
        }
        else {
            $ExplicitAdditions += $_ 
        }
    }
    foreach ($ExplicitAddition in $ExplicitAdditions) {
        $allAdditions += " -or (userPrincipleName -eq " + $ExplicitAddition + ")"
    }
    $reportHash.Add($store, $allAdditions)
    $x++
}
$reportedStores = $reportHash.Keys
$reportedAdds = $reportHash.Values
$reportHash | Out-File -FilePath C:\Temp\reportHash.txt -Force 
$reportedStores[0] | Out-File -FilePath C:\Temp\reportStores.txt -Force 
$reportedAdds[0] | Out-File -FilePath C:\Temp\reportAdds.txt

$reportHash.Keys | foreach-object {
    $adds += " " + $reportHash["$_"]
    $filterRule = 'user.Department -contains ' + '"' + $_.ToString() + '"' + ' -and user.extensionAttribute3 -eq "A" -and (user.extensionAttribute13...) ' 
    $out += $filterRule + $adds
    $out | Out-File -FilePath C:\Temp\whatIsSet.txt 
    #-id $storeinfo["$store"] -membershipRule "$filterRule + $adds"
    $storeinfo["$_"]
    $filterRule + $adds
    $adds = $null
}