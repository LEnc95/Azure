$groupName = $Request.Query.Name
$groupDesc = $Request.Query.Desc
$domainnames = $Request.Query.DomainName
$dynamicrule = ""
Foreach($domainname in $domainnames.Split(";"))
{
   $dynamicrule = $dynamicrule + "(user.userPrincipalName -contains ""_$domainname"") or";
}
$dynamicrule = $dynamicrule -replace ".{2}$"
$dynamicrule = $dynamicrule + "and (user.objectId -ne null)";
New-AzureADMSGroup -DisplayName $groupName -Description $groupDesc -MailEnabled $False -MailNickName "group" -SecurityEnabled $True -GroupTypes "DynamicMembership" -MembershipRule $dynamicrule -MembershipRuleProcessingState "On"