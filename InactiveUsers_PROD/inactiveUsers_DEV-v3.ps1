<#        
    .SYNOPSIS
     Set account expiration date to the past for users who have not signed into an on prem AD controller for 90days and have not signed into an cloud resource in 30days and user is not part of the exclusion list.

    .DESCRIPTION
    Get AD users within selected OUs.
    Filter those whose lastlogondate exceeds 90days
    Check users marked inactive for any sign in history in Azure over last 30 days.
    If no activity set account expiration date to a 2 days prior than the date of execution. 
    Add user to SG_Expired_Accounts AD group for reporting and to apply CA policy in Azure to block access for members of this group. 

    .NOTES
    ========================================================================
         Windows PowerShell Source File 
         Created with Love
         
         NAME: InactiveUsers
         
         AUTHOR: Encrapera, Luke 
         COAUTHOR: McClure, Brandon
         DATE  : 10/1/2021
         LastModified: 1/27/2022
         
         COMMENT: Set account expiration date to the past for users who have not signed into an on prem AD controller for 90days and have not signed into an cloud resource in 30days and user is not part of the exclusion list. 
    ==========================================================================
#>

#Secret Server Start
function Get-SecretServerCredential {
    [cmdletbinding()]
    param(
        [parameter(ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            ValueFromRemainingArguments = $false,
            Mandatory = $false)]
        [Alias('Name')]
        [string]$SecretName,
        [parameter(ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            ValueFromRemainingArguments = $false,
            Mandatory = $false)]
        [Alias('ID')]
        [int]$SecretID,
        [parameter(ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            ValueFromRemainingArguments = $false,
            Mandatory = $false)]
        [System.Management.Automation.PSCredential]$Credentials,
        [parameter(ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            ValueFromRemainingArguments = $false,
            Mandatory = $false)]
        [Alias('ComputerName')]
        [string]$SecretServerName = 'creds.gianteagle.com',
        [parameter(ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            ValueFromRemainingArguments = $false,
            Mandatory = $false)]
        [switch]$TLS12,
        [parameter(ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            ValueFromRemainingArguments = $false,
            Mandatory = $false)]
        [switch]$oAuth

    )
    if ($TLS12) {
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    }
    if ($SecretID -and $SecretName) {
        Write-Host 'Both ID and Name provided, using just the ID.'
    }
    $BaseURL = "https://$SecretServerName/SecretServer"
    $Arglist = @{}
    if ($oAuth) {
        try {
            $Arglist['Headers'] = @{Authorization = "Bearer $((Invoke-RestMethod "$BaseURL/oauth2/token" -Method Post -Body @{username = $Credentials.UserName; password = $Credentials.GetNetworkCredential().Password; grant_type = 'password'} -ErrorAction Stop).access_token)" }
        }
        catch {
            throw $_
        }
        $BaseURL += '/api/v1/secrets'
    }
    else {
        $BaseURL += '/winauthwebservices/api/v1/secrets'
        $Arglist['UseDefaultCredentials'] = $true
    }

    if ($SecretID) {
        $SecretServerSecretID = $SecretID
    }
    elseif ($SecretName) {
        $Arglist['Uri'] = "$($BaseURL)?filter.searchText=$SecretName"
        Write-Verbose 'Getting Secret ID:'
        $Arglist | Out-String | Write-Verbose
        $SecretServerSecretID = ((Invoke-RestMethod @Arglist).records | Where-Object { $_.name -eq $SecretName }).id
        Write-Verbose "Getting Secret ID: $SecretServerSecretID"
        if ($null -eq $SecretServerSecretID) {
            throw 'No Secret Found!'
        }
    }
    else {
        throw 'No Secret Identifier found, Please provide an ID or Name.'
    }

    $Arglist['Uri'] = "$BaseURL/$SecretServerSecretID"
    
    Write-Verbose 'Getting Secret:'
    $Arglist | Out-String | Write-Verbose
    $SecretServerSecret = Invoke-RestMethod @Arglist
    $SecretServerPassword = ($SecretServerSecret.items | Where-Object { $_.slug -eq 'password' }).itemValue | ConvertTo-SecureString -asPlainText -Force
    $SecretServerUserName = ($SecretServerSecret.items | Where-Object { $_.slug -eq 'username' }).itemValue
    if ($SecretServerUserName -like '') {
        $SecretServerUserName = '<null>'
    }
    $SecretServerDomainName = ($SecretServerSecret.items | Where-Object { $_.slug -eq 'domain' }).Value
    if ($SecretServerDomainName -notlike '') {
        $SecretServerUserName = "$SecretServerDomainName\$SecretServerUserName"
    }
    $SecretServerCredentials = New-Object System.Management.Automation.PSCredential($SecretServerUserName, $SecretServerPassword)
    return $SecretServerCredentials
}
[System.Management.Automation.PSCredential]$API_Keys = Get-SecretServerCredential -SecretID 31940 -TLS12
# Secret Server End

#Declare Variables
$mypath = $MyInvocation.MyCommand.Path
$parentDir = Split-Path $mypath -Parent
$DateTime = Get-Date -f "yyyy-MM-dd"
$InFileName = "inactiveExclusion.txt"
$exclusion = Get-Content -Path "$parentDir\$inFileName"
$users = @()
$expiredAccounts = @() #Collection of expired users UPNs
$limitedActivity = @()

#Get active users by OU
$OUs               = "OU=Contractors,OU=Users,OU=Managed Users & Computers,DC=corp,DC=gianteagle,DC=com", "OU=Corporate Users,OU=Users,OU=Managed Users & Computers,DC=corp,DC=gianteagle,DC=com", "OU=TCS,OU=Users,OU=Managed Users & Computers,DC=corp,DC=gianteagle,DC=com"
$LookBack_Date     = Get-Date (Get-Date).AddDays(-90) -Format 'yyyyMMdd000000.0Z'                         # LDAP DateTime for Creation Date
$LookBack_FileTime = (Get-Date).AddDays(-90).ToFileTime()                                                 # FileTime for Password and LastLogon
$LDAP_Lookup       = '(&'                                                                                 # Define LDAP as a AND across all filters
$LDAP_Lookup      += '(objectCategory=person)'                                                            # LDAP Person
$LDAP_Lookup      += '(objectClass=user)'                                                                 # LDAP User
$LDAP_Lookup      += '(!userAccountControl:1.2.840.113556.1.4.803:=2)'                                    # LDAP Enabled
$LDAP_Lookup      += '(!memberOf=CN=SG_Expired_Accounts,OU=Security Groups,DC=corp,DC=gianteagle,DC=com)' # LDAP Not a member of Expired Group
$LDAP_Lookup      += "(lastLogonTimeStamp<=$LookBack_FileTime)"                                           # LDAP LastLogon over 90 Days Ago
$LDAP_Lookup      += "(pwdLastSet<=$LookBack_FileTime)"                                                   # LDAP Password Set over 90 Days Ago
$LDAP_Lookup      += "(whenCreated<=$LookBack_Date)"                                                      # LDAP Created over 90 Days Ago
$LDAP_Lookup      += ')'                                                                                  # Close LDAP
foreach($OU in $OUs) {
    $users += Get-ADUser -LDAPFilter $LDAP_Lookup -SearchBase $OU -Property msDS-ExternalDirectoryObjectId, UserPrincipalName, DisplayName, lastLogonDate, whenCreated, memberof  | Where-Object { $_.DistinguishedName -notlike '*OU=Leadership,*'}
} 
$users = $users | Where-Object { $exclusion -notcontains $_.userPrincipalName } #Trim exclusions from set
$CSVFile = "$parentDir\" + "initSet" + "_" + $DateTime + ".csv" 
$users | Export-Csv -Path $CSVFile -NoTypeInformation -Force | Out-String -Width 10000 #Export inital set
Write-Host  "Initial users set has been exported to " $CSVFile #Print path to file

#SPLUNK STUFF
$Splunk_User = $env:USERNAME
$Splunk_Headers = @{Authorization = "Basic $([System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes("$($Splunk_User):$((Get-SecretServerCredential -SecretName "GIANTEAGLE\$($Splunk_User)" -TLS12).GetNetworkCredential().password)")))" }
if (-not ([System.Management.Automation.PSTypeName]'ServerCertificateValidationCallback').Type) {
    $certCallback = @"
    using System;
    using System.Net;
    using System.Net.Security;
    using System.Security.Cryptography.X509Certificates;
    public class ServerCertificateValidationCallback
    {
        public static void Ignore()
        {
            if(ServicePointManager.ServerCertificateValidationCallback ==null)
            {
                ServicePointManager.ServerCertificateValidationCallback += 
                    delegate
                    (
                        Object obj, 
                        X509Certificate certificate, 
                        X509Chain chain, 
                        SslPolicyErrors errors
                    )
                    {
                        return true;
                    };
            }
        }
    }
"@
    Add-Type $certCallback
}
[ServerCertificateValidationCallback]::Ignore()
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$Splunk_Body = @{
    search      = "inputlookup 90Day_Succ_Azure_Account_Activity.csv | search user IN (`"$($Users.UserPrincipalName -join '`",`"')`") | sort 0 +user | table user operatingSystem 90dCount Latest"
    output_mode = "json"
}
$Splunk_Results = (Invoke-RestMethod -Uri 'https://splunk-api.gianteagle.com:8089/services/search/jobs/oneshot' -Body $Splunk_Body -Method Post -Headers $Splunk_Headers).results
$Splunk_Results 

$expiredAccounts = $users | Where-Object {$Splunk_Results.user -notcontains $_.UserPrincipalName} #Add users to array that are not present in the splunk results
$expiredAccounts.UserPrincipalName

$Filtered_Splunk_Results = $Splunk_Results | Where-Object {$_.'90dCount' -lt 4}
$limitedActivity = $users | Where-Object {$Filtered_Splunk_Results.user -contains $_.UserPrincipalName} #Add users to array that are not present in the splunk results
$CSVFile = "$parentDir\" + "Limited_Activity_" + "_" + $DateTime + ".csv" 
$limitedActivity | Export-Csv -Path $CSVFile -NoTypeInformation -Force | Out-String -Width 10000 #Export limited activity set

$expiredaccounts | ForEach-Object {
    #Set-ADAccountExpiration -Identity $_.SamAccountName -TimeSpan -1.0:0 #-DateTime "10/18/2008
    #Add-ADGroupMember -Identity "SG_Expired_Accounts" -Members $_.SamAccountName
}
$OutFileName = "UsersExpired_"
$OutFile = "$parentDir\$OutFileName" + $DateTime + ".csv" 
$expiredaccounts | Export-Csv -Path $OutFile -Force -NoTypeInformation