#Cloud Account Check

#Connect to services
#Connect-AzureAD
#Connect-ExchangeOnline
#Connect-MsolService

#Functions
Function Azure {
    try { 
	    $var = Get-AzureADTenantDetail 
    } 
    catch [Microsoft.Open.Azure.AD.CommonLibrary.AadNeedAuthenticationException] { 
	    Write-Host "You're not connected to AzureAD";  
	    Write-Host "Make sure you have AzureAD module available on this system then use Connect-AzureAD to establish connection";  
        $UPN = whoami /upn
        Connect-AzureAD -AccountId $UPN
    }
}

function EXL($username,$param) {
    try{Get-MsolDomain -ErrorAction Stop > $null}
    catch{
            if ($cred -eq $null) {
            $UPN = Get-ADUser $env:USERNAME | select UserPrincipalName
            $cred = Get-Credential $UPN.UserPrincipalName
            }
            Write-Output "Connecting to Office 365..."
            Connect-MsolService -Credential $cred
          }
    if($param -eq $null){Get-MsolUser -SearchString "$username "}
    elseif($param -eq 'mfa' -or $param -eq '2f'){Get-MsolUser -SearchString $username | select -ExpandProperty strongauthenticationmethods}
    else{Get-MsolUser -SearchString $username, $param}
}

function ExchangeOnline {
    $UPN = Get-ADUser $env:USERNAME | select UserPrincipalName
    Connect-ExchangeOnline -UserPrincipalName $UPN.UserPrincipalName
    }


Function License($UPN) {
    #$upn = Read-Host "UPN "
    Get-MsolUser -UserPrincipalName $upn | Format-List DisplayName,Licenses
}

#Run
#Connect to services
Azure
ExchangeOnline
Exl

#Prompt user UPN
$UPN = Read-Host "UPN"

#Output
#Get-AzureADUser -ObjectId $UPN
Exl $UPN # Licensed online
License $UPN # All assgined azure license
Get-EXOMailbox $UPN | select ExternalDirectoryObjectId, UserPrincipalName, PrimarySmtpAddress, Name, Guid, RecipientType
Exl $UPN 2F #2 Factor Auth Method