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
$OUs = "OU=Contractors,OU=Users,OU=Managed Users & Computers,DC=corp,DC=gianteagle,DC=com", "OU=Corporate Users,OU=Users,OU=Managed Users & Computers,DC=corp,DC=gianteagle,DC=com", "OU=TCS,OU=Users,OU=Managed Users & Computers,DC=corp,DC=gianteagle,DC=com"
$InFileName = "inactiveExclusion.txt"
$exclusion = Get-Content -Path "$parentDir\$inFileName"
$users = @()
$inactive = @()

#Get active users by OU
ForEach ($OU in $OUs) {
    $OU_name = $OU.Split("=").split(",")[1]
    $CSVFile = "$parentDir\" + $OU_name + "_" + $DateTime + ".csv" 
    $users += Get-ADUser -Filter * -SearchBase $OU -Property msDS-ExternalDirectoryObjectId, UserPrincipalName, DisplayName, lastLogonDate, whenCreated, memberof <#-LDAPFilter "(whenCreated>=$timestampString)"#> | Where-Object { $_.enabled -EQ $TRUE -and $_.DistinguishedName -notlike '*OU=Leadership,*' -and !($_.memberof -like "*SG_Expired_Accounts*") -and $_.whenCreated -lt ((Get-Date).AddDays(-90)).Date <#-and $_.whenChanged -lt ((Get-Date).AddDays(-30)).Date#> }
}
$users = $users | Where-Object { $exclusion -notcontains $_.userPrincipalName } #Trim exclusions from set
$users | Export-Csv -Path $CSVFile -NoTypeInformation -Force | Out-String -Width 10000 #Export inital set
Write-Host $OU " has been exported to " $CSVFile #Print path to file

#Foreach user if lastlogondate exceeds 90 days pull sign ins from Azure. 
ForEach ($user in $users) {
    if ($user.lastLogonDate -lt (Get-Date).AddDays(-90)) {
        $inactive += $user.UserPrincipalName.ToLower()
    }
}
$OutFileName = "Inactive_"
$CSVFile = "$parentDir\$OutFileName" + $DateTime + ".txt" 
$inactive | Out-File -FilePath $CSVFile

$InactiveUsers = @()

$inactive | ForEach-Object {
    #region Authentication
    $ClientID = $API_Keys.UserName
    $ClientSecret = $API_Keys.GetNetworkCredential().Password
    $TenantDomain = 'fe7b0418-5142-4fcf-9440-7a0163adca0d'
    $LoginURL = 'https://login.microsoft.com'
    $Resource = 'https://graph.microsoft.com'
    $TokenRequestBody = @{grant_type = "client_credentials"; resource = $Resource; client_id = $ClientID; client_secret = $ClientSecret }
    $oAuth = Invoke-RestMethod -Method Post -Uri $LoginURL/$TenantDomain/oauth2/token?api-version=1.0 -Body $TokenRequestBody
    $AzureHeaders = @{'Authorization' = "$($oAuth.token_type) $($oAuth.access_token)" }
    #endregion Authentication

    [uri]$SignInsUrl = "https://graph.microsoft.com/v1.0/auditLogs/signIns?`$filter=userPrincipalName eq '$_'"
    try {
        $SignIns = Invoke-RestMethod -Uri $SignInsUrl.AbsoluteUri -Headers $AzureHeaders -ErrorAction Stop
        if ($SignIns.value.Count -eq 0 <#-and $SignInsUrl.value#>) {
            $InactiveUsers += $_
        }    
    }
    catch {
        $errors += $_
    }
}

$OutFileName = "erroredUsers_"
$OutFile = "$parentDir\$OutFileName" + $DateTime + ".txt" 
$errors | Out-File -FilePath $OutFile -Force
$OutFileName = "InactiveUsersTargeted_"
$OutFile = "$parentDir\$OutFileName" + $DateTime + ".txt" 
$InactiveUsers | Out-File -FilePath $OutFile -Force

#SPLUNK STUFF
$Users = @()
$Users = $InactiveUsers
#$Users += Get-Content -Path "C:\Users\914476\OneDrive - Giant Eagle, Inc\Documents\GitHub\Azure\InactiveUsers_PROD\InactiveUsersTargeted_2022-01-13.txt"
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
    search      = "inputlookup 90Day_Succ_Azure_Account_Activity.csv | search user IN (`"$($Users -join '`",`"')`") | sort 0 +user | table user operatingSystem 90dCount Latest"
    output_mode = "json"
}
$Splunk_Results = (Invoke-RestMethod -Uri 'https://splunk-api.gianteagle.com:8089/services/search/jobs/oneshot' -Body $Splunk_Body -Method Post -Headers $Splunk_Headers).results
$Splunk_Results 
$expiredAccounts = @()
$Users | ForEach-Object {
    $expiredAccounts += $_ | Where-Object { $_ -notin $Splunk_Results.user }
}

#SET USERS INACTIVE
$inactive = @()
$expiredAccounts
$expiredAccounts | ForEach-Object {
    $_
    $filter = "*" + $_ + "*"
    $inactive += Get-aduser -Filter { UserPrincipalName -like $filter }
}
$inactive | ForEach-Object {
    #Set-ADAccountExpiration -Identity $_.SamAccountName -TimeSpan -1.0:0 #-DateTime "10/18/2008
    #Add-ADGroupMember -Identity "SG_Expired_Accounts" -Members $_.SamAccountName
}
$OutFileName = "UsersToExpire_"
$OutFile = "$parentDir\$OutFileName" + $DateTime + ".csv" 
$inactive | Export-Csv -Path $OutFile -Force -NoTypeInformation