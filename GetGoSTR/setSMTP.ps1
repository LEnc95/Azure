#Connect-ExchangeOnline
$groups = "STR_GetGoCrewCentral","STR_GetGoCrewEast","STR_GetGoCrewWest","STR_GetGoCentral_Kitchen","STR_GetGoEast_Kitchen","STR_GetGoWest_Kitchen","STR_GetGoMTO","STR_GetGoNonKitchen","STR_GetGoPads","STR_GetGoCentral_StoreLeadership","STR_GetGoEast_StoreLeadership","STR_GetGoWest_StoreLeadership"
$groups | ForEach-Object{
    $smtp = "$_@groups.gianteagle.com"
    #Set-UnifiedGroup -Identity $_ -PrimarySmtpAddress $smtp
    Set-UnifiedGroup -Identity $_ -AutoSubscribeNewMembers
}
