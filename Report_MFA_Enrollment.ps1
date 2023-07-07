$users= @()
$report=@()
$UserPrincipalName=@()
$users = get-aduser -Filter {department -like "6376"}
$users | ForEach-Object {$UserPrincipalName += $_.UserPrincipalName}

foreach ($user in $UserPrincipalName) {
    try {
  $MsolUser = Get-MsolUser -UserPrincipalName $user -ErrorAction Stop

  $Method = ""
  $MFAMethod = $MsolUser.StrongAuthenticationMethods | Where-Object {$_.IsDefault -eq $true} | Select-Object -ExpandProperty MethodType

  If (($MsolUser.StrongAuthenticationRequirements) -or ($MsolUser.StrongAuthenticationMethods)) {
    Switch ($MFAMethod) {
        "OneWaySMS" { $Method = "SMS token" }
        "TwoWayVoiceMobile" { $Method = "Phone call verification" }
        "TwoWayVoiceOffice" { $Method = "Workphone call verification"}
        "PhoneAppOTP" { $Method = "Hardware token or authenticator app" }
        "PhoneAppNotification" { $Method = "Authenticator app" }
    }
  }

  $report += [PSCustomObject]@{
    DisplayName       = $MsolUser.DisplayName
    UserPrincipalName = $MsolUser.UserPrincipalName
    isAdmin           = if ($listAdmins -and $admins.EmailAddress -match $MsolUser.UserPrincipalName) {$true} else {"-"}
    MFAType           = $Method
    MFAEnforced       = if ($MsolUser.StrongAuthenticationRequirements) {$true} else {"-"}
    "Email Verification" = if ($msoluser.StrongAuthenticationUserDetails.Email) {$msoluser.StrongAuthenticationUserDetails.Email} else {"-"}
    "Registered phone" = if ($msoluser.StrongAuthenticationUserDetails.PhoneNumber) {$msoluser.StrongAuthenticationUserDetails.PhoneNumber} else {"-"}
  } 
}
    catch {
        [PSCustomObject]@{
            DisplayName       = " - Not found"
            UserPrincipalName = $User
            isAdmin           = $null
            MFAEnabled        = $null
        }
    }
} 
$report | Export-Csv -Path C:\Temp\MFAEnrollment.csv -NoTypeInformation