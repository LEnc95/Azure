$users = Get-Content -Path "C:\Users\914476\OneDrive - Giant Eagle, Inc\Documents\GitHub\_infile\User_EID2.csv"
$sam = @()
$objectID = @()
$results = @()
$ExternalDirectoryObjectId = @()
$users | foreach-object {
    $sam += $_.Split(",")[0]
}
#$sam = "800318", "601112"
$sam | ForEach-Object {
    $ExternalDirectoryObjectId += Get-ADUser -Identity $_ -Properties msDS-ExternalDirectoryObjectId | Select-Object msDS-ExternalDirectoryObjectId, DisplayName, SamaccountName
}
$ExternalDirectoryObjectId | ForEach-Object {
    $objectID += $_.'msDS-ExternalDirectoryObjectId'.Split("_")[1]
}
$objectID | ForEach-Object {
    $results += Get-AzureADUser -ObjectId $_ | Select-Object DisplayName, UserPrincipalName, AccountEnabled, ExtensionProperty
}
$results | Export-Csv -Path C:\Temp\ad2azure.csv