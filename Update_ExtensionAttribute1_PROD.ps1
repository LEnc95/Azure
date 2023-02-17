#Update EXT1 for SNow Manager maintainace
$sngroups = @()
$update = @()

$sngroups = Get-ADgroup -filter {samaccountname -like "SN_*"} -properties *
Write-Host "Group Count is: " $sngroups.count
$sngroups | Select-Object Samaccountname, extensionAttribute1, managedby 

$update = @([PSCustomObject]@{})
$sngroups | foreach-object {
    $update += [PSCustomObject]@{
        Name = $_.Samaccountname
        Manager = $_.managedby.split(",").split("=")[1]
    }
} 

#Update ext1 for those SN groups with ManagedBy populated.
$update | foreach-object {
   Set-ADgroup -identity $_.Name -Replace @{"extensionattribute1"="$($_.Manager)"}
}

$sngroups = Get-ADgroup -filter {samaccountname -like "SN_*"} -properties * | Select-Object Samaccountname, extensionAttribute1, managedby | Export-Csv -Path C:\Temp\SN_group_owners.csv -NoTypeInformation
