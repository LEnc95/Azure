# 1) Choose store
$store = '0047'

# 2) Resolve a single group (pick one explicitly)
# Option A: exact displayName if you know the suffix
$displayName = "${store}_FileMaintenance"   # adjust if different
$grp = Get-AzureADMSGroup -Filter "displayName eq '$displayName'"

# Option B: otherwise, pick the first match from a prefix search
if (-not $grp) { $grp = Get-AzureADMSGroup -Filter "startsWith(displayName,'$store')" | Select-Object -First 1 }

if (-not $grp) { throw "No group found for store $store." }
$gid = $grp.Id  # now a single string

# 3) Get existing rule
$old = (Get-AzureADMSGroup -Id $gid).MembershipRule

# 4) Extract/quote explicit additions
$additionMatches = [regex]::Matches($old, '(?i)\(user\.userPrincipalName\s*-eq\s*\"\"?([^\"\\)]+)\"\"?\)')
$quotedAdditions = @()
foreach ($m in $additionMatches) {
  $upn = $m.Groups[1].Value
  $quotedAdditions += " -or (user.userPrincipalName -eq `"$upn`")"
}

# 5) Remove old additions from base
$base = [regex]::Replace($old, '(?i)\s*-or\s*\(user\.userPrincipalName\s*-eq\s*\"\"?[^\"\\)]+\"\"?\)', '')

# 6) Set final rule (turn processing on)
$final = ($base.TrimEnd()) + ($quotedAdditions -join '')
Set-AzureADMSGroup -Id $gid -MembershipRule $final -MembershipRuleProcessingState "On"

# 7) Verify
$post = (Get-AzureADMSGroup -Id $gid).MembershipRule
"`nSTORE=$store`nID=$gid`nOLD=$old`nNEW=$final`nPOSTSET=$post`n" | Out-File -FilePath "C:\Temp\whatIsSet_singleStoreTest.txt" -Append
$post