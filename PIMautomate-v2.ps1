# PIM Role Checkout Script for Entra ID - Alternative Authentication
param(
    [string]$UserEmail = "",
    [int]$DurationHours = 1,
    [string]$Justification = "Activated via PowerShell script",
    [switch]$ListOnly = $false,
    [switch]$Verbose = $false
)

Write-Host "PIM Role Checkout Script for Entra ID (Alternative Auth)" -ForegroundColor Magenta
Write-Host "=====================================================" -ForegroundColor Magenta

# Clear any existing connections
Write-Host "Clearing existing connections..." -ForegroundColor Yellow
try {
    Disconnect-MgGraph -ErrorAction SilentlyContinue
} catch {
    # Ignore errors
}

# Try to update Microsoft Graph module
Write-Host "Checking Microsoft Graph module..." -ForegroundColor Yellow
try {
    $mgModule = Get-Module Microsoft.Graph -ListAvailable
    if ($mgModule) {
        Write-Host "Microsoft Graph module found: $($mgModule.Version)" -ForegroundColor Green
    } else {
        Write-Host "Installing Microsoft Graph module..." -ForegroundColor Yellow
        Install-Module Microsoft.Graph -Force -AllowClobber -Scope CurrentUser
        Write-Host "Microsoft Graph module installed" -ForegroundColor Green
    }
} catch {
    Write-Host "Warning: Could not check/install Microsoft Graph module" -ForegroundColor Yellow
}

# Connect to Microsoft Graph with interactive sign-in
Write-Host "Connecting to Microsoft Graph..." -ForegroundColor Yellow
Write-Host "You will be prompted to sign in interactively..." -ForegroundColor Cyan

$connected = $false

# Method 1: Interactive browser authentication
try {
    Write-Host "Attempting interactive browser authentication..." -ForegroundColor Yellow
    Connect-MgGraph -Scopes 'User.Read','RoleEligibilitySchedule.Read.Directory','RoleAssignmentSchedule.ReadWrite.Directory','Directory.Read.All' -ContextScope Process -ErrorAction Stop
    Write-Host "Connected with interactive authentication" -ForegroundColor Green
    $connected = $true
} catch {
    Write-Host "Interactive authentication failed, trying device code..." -ForegroundColor Yellow
    # Method 2: Try device code authentication
    try {
        Write-Host "Attempting device code authentication..." -ForegroundColor Yellow
        Write-Host "You will be prompted to visit a URL and enter a code..." -ForegroundColor Cyan
        Connect-MgGraph -Scopes 'User.Read','RoleEligibilitySchedule.Read.Directory','RoleAssignmentSchedule.ReadWrite.Directory','Directory.Read.All' -ContextScope Process -UseDeviceAuthentication -ErrorAction Stop
        Write-Host "Connected with device code authentication" -ForegroundColor Green
        $connected = $true
    } catch {
        Write-Host "Device code authentication failed, trying tenant-specific..." -ForegroundColor Yellow
        # Method 3: Try tenant-specific authentication
        try {
            Write-Host "Attempting tenant-specific authentication..." -ForegroundColor Yellow
            Connect-MgGraph -Scopes 'User.Read','RoleEligibilitySchedule.Read.Directory','RoleAssignmentSchedule.ReadWrite.Directory','Directory.Read.All' -ContextScope Process -TenantId "gianteagle.com" -ErrorAction Stop
            Write-Host "Connected with tenant-specific authentication" -ForegroundColor Green
            $connected = $true
        } catch {
            Write-Host "All authentication methods failed" -ForegroundColor Red
        }
    }
}

if (-not $connected) {
    Write-Host "All authentication methods failed." -ForegroundColor Red
    Write-Host ""
    Write-Host "Troubleshooting steps:" -ForegroundColor Cyan
    Write-Host "1. Update Microsoft Graph module:" -ForegroundColor White
    Write-Host "   Install-Module Microsoft.Graph -Force -AllowClobber" -ForegroundColor Gray
    Write-Host "2. Try running PowerShell as Administrator" -ForegroundColor White
    Write-Host "3. Check your internet connection" -ForegroundColor White
    Write-Host "4. Contact your IT administrator" -ForegroundColor White
    Write-Host ""
    Write-Host "Alternative: Use the Azure Portal to activate PIM roles manually." -ForegroundColor Yellow
    exit 1
}

# Get user information
if ([string]::IsNullOrEmpty($UserEmail)) {
    $context = Get-MgContext
    if ($context -and $context.Account) {
        $UserEmail = $context.Account
        Write-Host "Using authenticated account: $UserEmail" -ForegroundColor Cyan
    } else {
        $UserEmail = Read-Host "Enter user email address"
    }
}

Write-Host "Retrieving user information for: $UserEmail" -ForegroundColor Yellow
try {
    $user = Get-MgUser -UserId $UserEmail -ErrorAction Stop
    Write-Host "Found user: $($user.DisplayName) ($($user.UserPrincipalName))" -ForegroundColor Green
} catch {
    Write-Host "Failed to find user '$UserEmail': $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Cannot proceed without valid user information." -ForegroundColor Red
    exit 1
}

# Verify we have the necessary permissions
Write-Host "Verifying permissions..." -ForegroundColor Yellow
$context = Get-MgContext
if ($context) {
    Write-Host "Connected as: $($context.Account)" -ForegroundColor Green
    Write-Host "Tenant: $($context.TenantId)" -ForegroundColor Green
} else {
    Write-Host "Warning: Could not verify connection context" -ForegroundColor Yellow
}

# Get eligible roles
Write-Host "Retrieving eligible roles..." -ForegroundColor Yellow
try {
    $eligibleRoles = Get-MgRoleManagementDirectoryRoleEligibilitySchedule -Filter "principalId eq '$($user.Id)'" -ExpandProperty RoleDefinition -ErrorAction Stop
    Write-Host "Found $($eligibleRoles.Count) eligible roles" -ForegroundColor Green
} catch {
    Write-Host "Standard query failed, trying alternative approach..." -ForegroundColor Yellow
    try {
        $allRoles = Get-MgRoleManagementDirectoryRoleEligibilitySchedule -ExpandProperty RoleDefinition -ErrorAction Stop
        $eligibleRoles = $allRoles | Where-Object { $_.PrincipalId -eq $user.Id }
        Write-Host "Found $($eligibleRoles.Count) eligible roles (alternative method)" -ForegroundColor Green
    } catch {
        Write-Host "Failed to retrieve eligible roles: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "This might indicate insufficient permissions for PIM role management." -ForegroundColor Yellow
        Write-Host "Try using the Azure Portal to activate PIM roles manually." -ForegroundColor Yellow
        exit 0
    }
}

if (-not $eligibleRoles -or $eligibleRoles.Count -eq 0) {
    Write-Host "No eligible roles found for this user." -ForegroundColor Yellow
    Write-Host "This user may not have any PIM roles assigned or may not have the necessary permissions." -ForegroundColor Yellow
    exit 0
}

# Show current active roles
Write-Host "Checking for active roles..." -ForegroundColor Yellow
try {
    $activeRoles = Get-MgRoleManagementDirectoryRoleAssignmentSchedule -Filter "principalId eq '$($user.Id)' and status eq 'Active'" -ExpandProperty RoleDefinition
    if ($activeRoles -and $activeRoles.Count -gt 0) {
        Write-Host "`nCurrently Active Roles:" -ForegroundColor Yellow
        Write-Host "======================" -ForegroundColor Yellow
        foreach ($role in $activeRoles) {
            Write-Host "• $($role.RoleDefinition.DisplayName)" -ForegroundColor Green
        }
        Write-Host ""
    }
} catch {
    if ($Verbose) { Write-Host "Could not retrieve active roles: $($_.Exception.Message)" -ForegroundColor Cyan }
}

# Display eligible roles
Write-Host "`nAvailable PIM Roles:" -ForegroundColor Cyan
Write-Host "===================" -ForegroundColor Cyan

$roleChoices = @()
for ($i = 0; $i -lt $eligibleRoles.Count; $i++) {
    $role = $eligibleRoles[$i]
    $choice = [PSCustomObject]@{
        Index = $i + 1
        RoleName = $role.RoleDefinition.DisplayName
        RoleId = $role.RoleDefinition.Id
        ScheduleId = $role.Id
        ExpirationDate = if ($role.EndDateTime) { $role.EndDateTime.ToString("yyyy-MM-dd HH:mm") } else { "No expiration" }
    }
    $roleChoices += $choice
    
    Write-Host "$($i + 1). $($role.RoleDefinition.DisplayName)" -ForegroundColor White
    Write-Host "   Expires: $($choice.ExpirationDate)" -ForegroundColor Gray
}

if ($ListOnly) {
    Write-Host "`nList-only mode completed." -ForegroundColor Cyan
    exit 0
}

# Interactive role selection and activation
Write-Host "`nRole Selection:" -ForegroundColor Cyan
Write-Host "===============" -ForegroundColor Cyan

$continue = $true
while ($continue) {
    $selection = Read-Host "Enter the number of the role you want to activate (or 'q' to quit)"
    
    if ($selection -eq 'q' -or $selection -eq 'Q') {
        Write-Host "Exiting..." -ForegroundColor Yellow
        $continue = $false
    } else {
        $selectedIndex = [int]$selection - 1
        if ($selectedIndex -ge 0 -and $selectedIndex -lt $roleChoices.Count) {
            $selectedRole = $roleChoices[$selectedIndex]
            Write-Host "Selected: $($selectedRole.RoleName)" -ForegroundColor Cyan
            
            # Confirm activation
            $confirm = Read-Host "Activate this role for $DurationHours hour(s)? (y/n)"
            if ($confirm -eq 'y' -or $confirm -eq 'Y') {
                Write-Host "Activating role..." -ForegroundColor Yellow
                
                try {
                    $startDateTime = (Get-Date).ToUniversalTime()
                    $endDateTime = $startDateTime.AddHours($DurationHours)
                    
                    $params = @{
                        Action = "selfActivate"
                        Justification = $Justification
                        PrincipalId = $user.Id
                        RoleDefinitionId = $selectedRole.RoleId
                        DirectoryScopeId = "/"
                        ScheduleInfo = @{
                            StartDateTime = $startDateTime
                            EndDateTime = $endDateTime
                        }
                    }
                    
                    New-MgRoleManagementDirectoryRoleAssignmentScheduleRequest -BodyParameter $params -ErrorAction Stop
                    Write-Host "Successfully requested role activation" -ForegroundColor Green
                    Write-Host "  Activation will last for $DurationHours hour(s)" -ForegroundColor Cyan
                    Write-Host "  Start: $($startDateTime.ToString('yyyy-MM-dd HH:mm UTC'))" -ForegroundColor Cyan
                    Write-Host "  End: $($endDateTime.ToString('yyyy-MM-dd HH:mm UTC'))" -ForegroundColor Cyan
                    Write-Host "`nRole activation requested successfully!" -ForegroundColor Green
                } catch {
                    Write-Host "Failed to activate role: $($_.Exception.Message)" -ForegroundColor Red
                    Write-Host "You may need to use the Azure Portal to activate this role manually." -ForegroundColor Yellow
                }
            }
            $continue = $false
        } else {
            Write-Host "Invalid selection. Please try again." -ForegroundColor Red
        }
    }
}

Write-Host "`nScript completed." -ForegroundColor Cyan
