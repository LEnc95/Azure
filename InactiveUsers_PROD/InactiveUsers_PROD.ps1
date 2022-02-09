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
         DATE  : 10/1/2021
         
         COMMENT: Set account expiration date to the past for users who have not signed into an on prem AD controller for 90days and have not signed into an cloud resource in 30days and user is not part of the exclusion list. 
         
    ==========================================================================
#>

#Declare Variables
$mypath = $MyInvocation.MyCommand.Path
$parentDir = Split-Path $mypath -Parent
$DateTime = Get-Date -f "yyyy-MM-dd"
$OUs = "OU=Contractors,OU=Users,OU=Managed Users & Computers,DC=corp,DC=gianteagle,DC=com", "OU=Corporate Users,OU=Users,OU=Managed Users & Computers,DC=corp,DC=gianteagle,DC=com", "OU=TCS,OU=Users,OU=Managed Users & Computers,DC=corp,DC=gianteagle,DC=com"
$InFileName = "inactiveExclusion.txt"
$exclusion = Get-Content -Path "$parentDir\$inFileName"
$users = @()
$inactive = @()


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

#Get active users by OU
ForEach ($OU in $OUs) {
    $OU_name = $OU.Split("=").split(",")[1]
    $CSVFile = "$parentDir\" + $OU_name + "_" + $DateTime + ".csv" 
    $users += Get-ADUser -Filter * -SearchBase $OU -Property msDS-ExternalDirectoryObjectId, UserPrincipalName, DisplayName, lastLogonDate, whenCreated, memberof <#-LDAPFilter "(whenCreated>=$timestampString)"#> | Where-Object { $_.enabled -EQ $TRUE -and $_.DistinguishedName -notlike '*OU=Leadership,*' -and !($_.memberof -like "*SG_Expired_Accounts*") -and $_.whenCreated -lt ((Get-Date).AddDays(-90)).Date <#-and $_.whenChanged -lt ((Get-Date).AddDays(-30)).Date#>}
}
$users = $users | Where-Object { $exclusion -notcontains $_.userPrincipalName }
$users | Export-Csv -Path $CSVFile -NoTypeInformation -Force | Out-String -Width 10000
Write-Host $OU " has been exported to " $CSVFile

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
<# $inactive | foreach-object  {
    #IMPORT AZURE SIGNIN DATA
    Get-Content -Path -
} #>
$OutFileName = "erroredUsers_"
$OutFile = "$parentDir\$OutFileName" + $DateTime + ".txt" 
$errors | Out-File -FilePath $OutFile -Force
$OutFileName = "InactiveUsersTargeted_"
$OutFile = "$parentDir\$OutFileName" + $DateTime + ".txt" 
$InactiveUsers | Out-File -FilePath $OutFile -Force
$expiredAccounts = @()
$InactiveUsers | ForEach-Object {
    $_
    $filter = "*" + $_ + "*"
    $expiredAccounts += Get-aduser -Filter { UserPrincipalName -like $filter }
}
$OutFile = "$parentDir\$OutFileName" + $DateTime + ".csv" 
$expiredAccounts | Export-Csv -Path $OutFile -Force -NoTypeInformation
$expiredAccounts | ForEach-Object {
    #Set-ADAccountExpiration -Identity $_.SamAccountName -TimeSpan -1.0:0 #-DateTime "10/18/2008
    #Add-ADGroupMember -Identity "SG_Expired_Accounts" -Members $_.SamAccountName
}
