$mypath = $MyInvocation.MyCommand.Path
$parentDir = Split-Path $mypath -Parent
$report = @()

$data = Import-Csv -Path "C:\Users\914476\OneDrive - Giant Eagle, Inc\Documents\GitHub\Azure\SSPR\sspr.csv"
$data | foreach-object {
    $report += Get-aduser -Filter {DisplayName -like '$_'} -Properties DisplayName, SamAccountName, department | Select-Object DisplayName, SamaccountName, department
}
$report | Export-Csv -Path "$parentDir/SSPR-NotRegistered.csv" -NoTypeInformation
$report | Export-Csv -Path "$parentDir/SSPR-NotRegistered.txt" -NoTypeInformation
