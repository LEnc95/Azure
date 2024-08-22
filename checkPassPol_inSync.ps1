#$u = "s4050gso"
#Get-ADUser -Identity $u -Properties *

#path to this file
#$scriptPath = "C:\Users\914476\Documents\Github\Azure\checkPassPol_inSync.ps1"
#.\$scriptPath
$users = @()
#get all users in this OU: OU=Retail Users GPP,OU=Users,OU=Managed Users & Computers,DC=corp,DC=gianteagle,DC=com where the account name starts with s
$users = Get-ADUser -Filter {SamAccountName -like "s*" -and Enabled -eq $true} -SearchBase "OU=Retail Users GPP,OU=Users,OU=Managed Users & Computers,DC=corp,DC=gianteagle,DC=com" -Properties PasswordNeverExpires
#print all users account names and thier password never expires flag
foreach ($user in $users) {
    #get the users azure password policy
    $cloudFlag = ""
    $azureUser = ""
    $azureUser = Get-AzureADUser -ObjectId $user.UserPrincipalName
    $cloudFlag = $azureUser | select PasswordPolicies
    Write-Host $user.SamAccountName $user.PasswordNeverExpires $cloudFlag.PasswordPolicies
    # output write host to text file
    Write-Output $user.SamAccountName $user.PasswordNeverExpires $cloudFlag.PasswordPolicies | Out-File -FilePath "C:\Users\914476\Documents\Github\Azure\checkPassPol_inSync.txt" -Append


}

# export console to text file