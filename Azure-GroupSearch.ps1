$report = Get-ADGroup -Filter {DisplayName -like "*_Key_Carriers*"} 
$report | export-csv -Path C:\Users\914476\documents\github\_outfile\KeyCarriersGroups.csv -Force
