### Clean up phone authentication methods for all Azure AD users ###

<#
    Set the registered applications ClientID and ClientSecret further down. This script requires the following Microsoft Graph permissions:
    Delegated:
        UserAuthenticationMethod.ReadWrite.All
        Reports.Read.All

    It also requires the DCToolbox PowerShell module:
    Install-Module -Name DCToolbox -Force

    Note that this script cannot delete a users phone method if it is set as the default authentication method. Microsoft Graph cannot, as of 7/10 2021, manage the default authentication method for users in Azure AD. Hopefully the users method of choice was changed when he/she switched to the Microsoft Authenticator app or another MFA/passwordless authentication method. If not, ask them to change the default method before running the script.

    Use the following report to understand how many users are registered for phone authentication (can lag up to 48 hours): https://portal.azure.com/#blade/Microsoft_AAD_IAM/AuthenticationMethodsMenuBlade/AuthMethodsActivity
#>


# Connect to Microsoft Graph with delegated permissions.
Write-Verbose -Verbose -Message 'Connecting to Microsoft Graph...'
$Parameters = @{
    ClientID     = ''
    ClientSecret = ''
}

$AccessToken = Connect-DCMsGraphAsDelegated @Parameters


# Fetch all users with phone authentication enabled from the Azure AD authentication usage report (we're using this usage report to save time and resources when querying Graph, but their might be a 24 hour delay in the report data).
Write-Verbose -Verbose -Message 'Fetching all users with any phone authentication methods registered...'
$Parameters = @{
    AccessToken = $AccessToken
    GraphMethod = 'GET'
    GraphUri    = "https://graph.microsoft.com/beta/reports/credentialUserRegistrationDetails?`$filter=authMethods/any(t:t eq microsoft.graph.registrationAuthMethod'mobilePhone') or authMethods/any(t:t eq microsoft.graph.registrationAuthMethod'officePhone')"
}

$AllUsersWithPhoneAuthentication = Invoke-DCMsGraphQuery @Parameters


# Output the number of users found.
Write-Verbose -Verbose -Message "Found $($AllUsersWithPhoneAuthentication.Count) users!"


# Loop through all those users.
$ProgressCounter = 0
foreach ($User in $AllUsersWithPhoneAuthentication) {
    # Show progress bar.
    $ProgressCounter += 1
    [int]$PercentComplete = ($ProgressCounter / $AllUsersWithPhoneAuthentication.Count) * 100
    Write-Progress -PercentComplete $PercentComplete -Activity "Processing user $ProgressCounter of $($AllUsersWithPhoneAuthentication.Count)" -Status "$PercentComplete% Complete"

    # Retrieve a list of registered phone authentication methods for the user. This will return up to three objects, as a user can have up to three phones usable for authentication.
    Write-Verbose -Verbose -Message "Fetching phone methods for $($User.userPrincipalName)..."
    $Parameters = @{
        AccessToken = $AccessToken
        GraphMethod = 'GET'
        GraphUri    = "https://graph.microsoft.com/beta/users/$($User.userPrincipalName)/authentication/phoneMethods"
    }

    $phoneMethods = Invoke-DCMsGraphQuery @Parameters

    <#
        The value of id corresponding to the phoneType to delete is one of the following:

        b6332ec1-7057-4abe-9331-3d72feddfe41 to delete the alternateMobile phoneType.
        e37fc753-ff3b-4958-9484-eaa9425c82bc to delete the office phoneType.
        3179e48a-750b-4051-897c-87b9720928f7 to delete the mobile phoneType.
    #>

    # Loop through all user phone methods.
    foreach ($phoneMethod in $phoneMethods) {
        # Delete the phone method.
        try {
            if ($phoneMethod.phoneType) {
                Write-Verbose -Verbose -Message "Deleting phone method '$($phoneMethod.phoneType)' for $($User.userPrincipalName)..."
                $Parameters = @{
                    AccessToken = $AccessToken
                    GraphMethod = 'DELETE'
                    GraphUri    = "https://graph.microsoft.com/beta/users/$($User.userPrincipalName)/authentication/phoneMethods/$($phoneMethod.id)"
                }

                Invoke-DCMsGraphQuery @Parameters | Out-Null
            }
        }
        catch {
            Write-Warning -Message "Could not delete phone method '$($phoneMethod.phoneType)' for $($User.userPrincipalName)! Is it the users default authentication method?"
        }
    }
}


break

# BONUS SCRIPT: LIST ALL GUEST USERS WITH SMS AS A REGISTERED AUTHENTICATION METHOD.

# First, create app registration and grant it:
#  User.Read.All
#  UserAuthenticationMethod.Read.All
#  Reports.Read.All


# Connect to Microsoft Graph with delegated permissions.
Write-Verbose -Verbose -Message 'Connecting to Microsoft Graph...'
$Parameters = @{
    ClientID = ''
    ClientSecret = ''
}

$AccessToken = Connect-DCMsGraphAsDelegated @Parameters


# Fetch user authentication methods.
Write-Verbose -Verbose -Message 'Fetching all users with any phone authentication methods registered...'
$Parameters = @{
    AccessToken = $AccessToken
    GraphMethod = 'GET'
    GraphUri    = "https://graph.microsoft.com/beta/reports/credentialUserRegistrationDetails?`$filter=authMethods/any(t:t eq microsoft.graph.registrationAuthMethod'mobilePhone') or authMethods/any(t:t eq microsoft.graph.registrationAuthMethod'officePhone')"
}

$AllUsersWithPhoneAuthentication = Invoke-DCMsGraphQuery @Parameters


# Fetch all guest users.
Write-Verbose -Verbose -Message 'Fetching all guest users...'
$Parameters = @{
    AccessToken = $AccessToken
    GraphMethod = 'GET'
    GraphUri    = "https://graph.microsoft.com/beta/users?`$filter=userType eq 'Guest'"
}

$AllGuestUsers = Invoke-DCMsGraphQuery @Parameters


# Check how many users who have an authentication phone number registered.
foreach ($Guest in $AllGuestUsers) {
    if ($AllUsersWithPhoneAuthentication.userPrincipalName.Contains($Guest.UserPrincipalName)) {
        Write-Output "$($Guest.displayName) ($($Guest.mail))"
    }
}
                            