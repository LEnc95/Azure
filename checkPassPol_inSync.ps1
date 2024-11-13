#$u = "s4050gso"
#Get-ADUser -Identity $u -Properties *

#path to this file
#$scriptPath = "C:\Users\914476\Documents\Github\Azure\checkPassPol_inSync.ps1"
#.\$scriptPath
$users = @()
#get all users in this OU: OU=Retail Users GPP,OU=Users,OU=Managed Users & Computers,DC=corp,DC=gianteagle,DC=com where the account name starts with s and ends in xrx
$users = Get-ADUser -Filter {SamAccountName -like "s*xrx"} -SearchBase "OU=Retail Users GPP,OU=Users,OU=Managed Users & Computers,DC=corp,DC=gianteagle,DC=com" -Properties PasswordNeverExpires, UserPrincipalName

$results = @()

#print all users account names and thier password never expires flag
foreach ($user in $users) {
    #get the users azure password policy
    $cloudFlag = ""
    $azureUser = ""
    # try to get the azure ad user by user principal name and if they are not found update the user.userprincipalname to replace everything after the @ with @gianteagle.onmicrosoft.com and try to get the user again
    try {
        $azureUser = Get-AzureADUser -ObjectId $user.UserPrincipalName
        $cloudFlag = $azureUser | select PasswordPolicies
    } catch {
        $user.UserPrincipalName = $user.UserPrincipalName -replace "@.*", "@gianteagle.onmicrosoft.com"
        $azureUser = Get-AzureADUser -ObjectId $user.UserPrincipalName
        $cloudFlag = $azureUser | select PasswordPolicies
    }
    #$azureUser = Get-AzureADUser -ObjectId $user.UserPrincipalName
    $cloudFlag = $azureUser | select PasswordPolicies
    Write-Host $user.SamAccountName $user.PasswordNeverExpires $cloudFlag.PasswordPolicies
    # output write host to text file
    #Write-Output $user.SamAccountName $user.PasswordNeverExpires $cloudFlag.PasswordPolicies | Out-File -FilePath "C:\Users\914476\Documents\Github\Azure\checkPassPol_inSync.txt" -Append
    #if the user has password flag set in AD and not in Azure, set the flag in Azure
     if ($user.PasswordNeverExpires -eq $true -and $cloudFlag.PasswordPolicies -ne "DisablePasswordExpiration") {
        Set-AzureADUser -ObjectId $user.UserPrincipalName -PasswordPolicies DisablePasswordExpiration
        Write-Host "Password policy set for " $user.SamAccountName
        # output write host to text file
        Write-Output "Password policy set for " $user.SamAccountName | Out-File -FilePath "C:\Users\914476\Documents\Github\Azure\checkPassPol_inSync.txt" -Append
    }


    # $results should have users account name, password never expires flag, and cloud password policy
    $results += [PSCustomObject]@{
        SamAccountName = $user.SamAccountName
        PasswordNeverExpires = $user.PasswordNeverExpires
        CloudPasswordPolicy = $cloudFlag.PasswordPolicies
    }
}
# output each users account name, password never expires flag, and cloud password policy to csv file    
$results | Export-Csv -Path "C:\temp\checkPassPol_inSync.csv" -NoTypeInformation

# export console to text file