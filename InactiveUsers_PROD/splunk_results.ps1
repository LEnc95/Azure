<# Secret Server Creds#>
function Get-SecretServerCredential {
    [cmdletbinding()]
    param(
        [parameter(ValueFromPipeline=$true,
                   ValueFromPipelineByPropertyName=$true,
                   ValueFromRemainingArguments=$false,
                   Mandatory=$false)]
                  [Alias('Name')]
                  [string]$SecretName,
        [parameter(ValueFromPipeline=$true,
                   ValueFromPipelineByPropertyName=$true,
                   ValueFromRemainingArguments=$false,
                   Mandatory=$false)]
                  [Alias('ID')]
                  [int]$SecretID,
        [parameter(ValueFromPipeline=$true,
                   ValueFromPipelineByPropertyName=$true,
                   ValueFromRemainingArguments=$false,
                   Mandatory=$false)]
                  [System.Management.Automation.PSCredential]$Credentials,
        [parameter(ValueFromPipeline=$true,
                   ValueFromPipelineByPropertyName=$true,
                   ValueFromRemainingArguments=$false,
                   Mandatory=$false)]
                  [Alias('ComputerName')]
                  [string]$SecretServerName = 'creds.gianteagle.com',
        [parameter(ValueFromPipeline=$true,
                   ValueFromPipelineByPropertyName=$true,
                   ValueFromRemainingArguments=$false,
                   Mandatory=$false)]
                  [switch]$TLS12,
        [parameter(ValueFromPipeline=$true,
                   ValueFromPipelineByPropertyName=$true,
                   ValueFromRemainingArguments=$false,
                   Mandatory=$false)]
                  [switch]$oAuth
 
    )
    if($TLS12) {
            [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    }
    if($SecretID -and $SecretName) {
        Write-Host 'Both ID and Name provided, using just the ID.'
    }
    $BaseURL = "https://$SecretServerName/SecretServer"
    $Arglist = @{}
    if($oAuth) {
        try {
            $Arglist['Headers'] = @{Authorization = "Bearer $((Invoke-RestMethod "$BaseURL/oauth2/token" -Method Post -Body @{username = $Credentials.UserName; password = $Credentials.GetNetworkCredential().Password; grant_type = 'password'} -ErrorAction Stop).access_token)"}
        } catch {
            throw $_
        }
        $BaseURL += '/api/v1/secrets'
    } else {
        $BaseURL += '/winauthwebservices/api/v1/secrets'
        $Arglist['UseDefaultCredentials'] = $true
    }
 
    if($SecretID) {
        $SecretServerSecretID = $SecretID
    } elseif($SecretName) {
        $Arglist['Uri'] = "$($BaseURL)?filter.searchText=$SecretName"
        Write-Verbose 'Getting Secret ID:'
        $Arglist | Out-String | Write-Verbose
        $SecretServerSecretID = ((Invoke-RestMethod @Arglist).records | Where-Object {$_.name -eq $SecretName}).id
        Write-Verbose "Getting Secret ID: $SecretServerSecretID"
        if($null -eq $SecretServerSecretID) {
            throw 'No Secret Found!'
        }
    } else {
        throw 'No Secret Identifier found, Please provide an ID or Name.'
    }
 
    $Arglist['Uri'] = "$BaseURL/$SecretServerSecretID"
    
    Write-Verbose 'Getting Secret:'
    $Arglist | Out-String | Write-Verbose
    $SecretServerSecret = Invoke-RestMethod @Arglist
    $SecretServerPassword = ($SecretServerSecret.items | Where-Object {$_.slug -eq 'password'}).itemValue | ConvertTo-SecureString -asPlainText -Force
    $SecretServerUserName = ($SecretServerSecret.items | Where-Object {$_.slug -eq 'username'}).itemValue
    if($SecretServerUserName -like '') {
        $SecretServerUserName = '<null>'
    }
    $SecretServerDomainName = ($SecretServerSecret.items | Where-Object {$_.slug -eq 'domain'}).Value
    if($SecretServerDomainName -notlike '') {
        $SecretServerUserName = "$SecretServerDomainName\$SecretServerUserName"
    }
    $SecretServerCredentials = New-Object System.Management.Automation.PSCredential($SecretServerUserName,$SecretServerPassword)
    return $SecretServerCredentials
}

<# Splunk #>
<#$Users = @(
    'brandon.mcclure@gianteagle.com',
    'caitlin.price@gianteagle.com',
    'luke.encrapera@gianteagle.com',
    'adam.werner2@gianteagle.com',
    'david.karem@gianteagle.com',
    'terrence.john@gianteagle.com',
    'joe.wentzel@gianteagle.com',
    'andy.fleckenstein@gianteagle.com',
    'rachel.lucas@gianteagle.com',
    'vinolia.baltharaj@gianteagle.com'
)#>
$Users = @()
$Users += Get-Content -Path "C:\Users\914476\OneDrive - Giant Eagle, Inc\Documents\GitHub\Azure\InactiveUsers_PROD\InactiveUsersTargeted_2022-01-13.txt"
$Splunk_User = $env:USERNAME
$Splunk_Headers = @{Authorization = "Basic $([System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes("$($Splunk_User):$((Get-SecretServerCredential -SecretName "GIANTEAGLE\$($Splunk_User)" -TLS12).GetNetworkCredential().password)")))"}
if (-not ([System.Management.Automation.PSTypeName]'ServerCertificateValidationCallback').Type)
{
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
    search = "inputlookup 90Day_Succ_Azure_Account_Activity.csv | search user IN (`"$($Users -join '`",`"')`") | sort 0 +user | table user operatingSystem 90dCount Latest"
    output_mode = "json"
}
$Splunk_Results = (Invoke-RestMethod -Uri 'https://splunk-api.gianteagle.com:8089/services/search/jobs/oneshot' -Body $Splunk_Body -Method Post -Headers $Splunk_Headers).results
$Splunk_Results 
$expiredAccounts = @()
$Users | ForEach-Object {
    $expiredAccounts += $_ | Where-Object {$_ -notin $Splunk_Results.user}
}
$expiredAccounts 