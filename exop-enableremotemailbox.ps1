Function EXOP
{
    $creds = Get-Credential $env:USERNAME
    $EXOPSession = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri http://excas10inf1.corp.gianteagle.com/PowerShell/ -Authentication Kerberos -Credential $creds
    $chost = [ConsoleColor]::Green
    try{
        Import-PSSession $EXOPSession -AllowClobber -DisableNameChecking
        write-host "Connected - Exchange On-Prem" -n -f $chost
    }
    catch{Write-Host "Connection Failed to excas10inf1.corp.gianteagle.com"}
}


EXOP
$remoteMailboxes = Get-ADUser -Identity "1136038" -Properties sAMAccountName, mailNickname, employeeID, msExchRemoteRecipientType, extensionAttribute5
#$remoteMailboxes.Count
foreach ($remoteMailbox in $remoteMailboxes)
{​​​​​
    $alias = $remoteMailbox.mailNickname
    #$alias
    $RemoteRoutingAddress= "$($alias)@gianteagle.mail.onmicrosoft.com"
    Enable-RemoteMailbox $alias -RemoteRoutingAddress $RemoteRoutingAddress
}​​​​​