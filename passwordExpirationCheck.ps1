<######################################  
#SYNOPSIS  
#     Check Password Expiration time stamp for TM in AD & Azure.
#DESCRIPTION 
#     Check Password Expiration time stamp for TM in AD & Azure. Purpose to confirm timestamps are in sync. Note Dates should match but hours will not be identical.  
#NOTES  
#    File Name  : passwordExpirationCheck.ps1
#    Author     : Luke Encrapera
#    Email      : luke.encrapera@gianteagle.com
#    Requires   : PowerShell V2+, MS Online sign in       
######################################>
Connect-MsolService
$user = Read-Host 'ID'
$user = Get-aduser $user -Properties * 
Write-Host "Active Directory ", $user.PasswordLastSet
$azureUser = Get-MsolUser -UserPrincipalName $user.UserPrincipalName
Write-Host "Azure ", $azureUser.LastPasswordChangeTimestamp
