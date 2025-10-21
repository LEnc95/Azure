# Connect to Microsoft Graph with multiple fallback authentication methods
Write-Output "Connecting to Microsoft Graph..."

# Method 1: Try with specific tenant ID (most reliable for corporate environments)
try {
    Connect-MgGraph -Scopes 'RoleEligibilitySchedule.Read.Directory','RoleAssignmentSchedule.ReadWrite.Directory','Directory.Read.All' -ContextScope Process -TenantId "gianteagle.com"
    Write-Output "Successfully connected to Microsoft Graph using tenant-specific authentication."
} catch {
    Write-Output "Tenant-specific authentication failed, trying default authentication..."
    
    # Method 2: Try default authentication
    try {
        Connect-MgGraph -Scopes 'RoleEligibilitySchedule.Read.Directory','RoleAssignmentSchedule.ReadWrite.Directory','Directory.Read.All' -ContextScope Process
        Write-Output "Successfully connected using default authentication."
    } catch {
        Write-Output "Default authentication failed, trying device code authentication..."
        
        # Method 3: Try device code authentication
        try {
            Connect-MgGraph -Scopes 'RoleEligibilitySchedule.Read.Directory','RoleAssignmentSchedule.ReadWrite.Directory','Directory.Read.All' -ContextScope Process -UseDeviceAuthentication
            Write-Output "Successfully connected using device code authentication."
        } catch {
            Write-Error "All authentication methods failed: $($_.Exception.Message)"
            Write-Output ""
            Write-Output "Troubleshooting steps:"
            Write-Output "1. Update Microsoft Graph PowerShell module:"
            Write-Output "   Install-Module Microsoft.Graph -Force -AllowClobber"
            Write-Output "2. Clear any existing connections:"
            Write-Output "   Disconnect-MgGraph"
            Write-Output "3. Try running the script again"
            exit 1
        }
    }
}

# Verify connection is working by testing a simple Graph call
try {
    Write-Output "Verifying connection..."
    $context = Get-MgContext
    if ($context) {
        Write-Output "Connected to tenant: $($context.TenantId)"
        Write-Output "Account: $($context.Account)"
    }
} catch {
    Write-Warning "Could not verify connection context, but continuing..."
}

# Get your user ID automatically from the authenticated context
try {
    Write-Output "Retrieving current user information..."
    
    # First, try to get the current user from the context
    $context = Get-MgContext
    if ($context -and $context.Account) {
        Write-Output "Authenticated as: $($context.Account)"
        
        # Try to get current user info using the authenticated account
        try {
            $me = Get-MgUser -UserId $context.Account
            Write-Output "Successfully retrieved user information for: $($me.DisplayName)"
        } catch {
            Write-Output "Could not retrieve user by account, trying by email..."
            # Fallback to the hardcoded email
            $me = Get-MgUser -UserId 'luke.encrapera@gianteagle.com'
            Write-Output "Successfully retrieved user information for: $($me.DisplayName)"
        }
    } else {
        Write-Output "No context found, trying direct user lookup..."
        $me = Get-MgUser -UserId 'luke.encrapera@gianteagle.com'
        Write-Output "Successfully retrieved user information for: $($me.DisplayName)"
    }
} catch {
    Write-Error "Failed to retrieve user information: $($_.Exception.Message)"
    Write-Output "This might indicate an authentication or permission issue."
    Write-Output "Trying alternative approach..."
    
    # Alternative: Use the account from context directly
    try {
        $context = Get-MgContext
        if ($context -and $context.Account) {
            Write-Output "Using account from context: $($context.Account)"
            # Extract user ID from the account (usually in format like "user@domain.com")
            $userId = $context.Account
            Write-Output "Using account as user ID: $userId"
        } else {
            Write-Error "No valid context or account found. Cannot proceed."
            exit 1
        }
    } catch {
        Write-Error "All methods to get user information failed: $($_.Exception.Message)"
        exit 1
    }
}

# Set userId for the rest of the script
if (-not $userId) {
    $userId = $me.Id
}

# Debug information
Write-Output "Using User ID: $userId"
Write-Output "User ID type: $($userId.GetType().Name)"

# Retrieve eligible roles
try {
    Write-Output "Retrieving eligible roles..."
    Write-Output "Searching for roles with principalId: $userId"
    
    # Try the standard query first
    $eligibleRoles = Get-MgRoleManagementDirectoryRoleEligibilitySchedule -Filter "principalId eq '$userId'" -ExpandProperty RoleDefinition
    Write-Output "Successfully retrieved role information."
} catch {
    Write-Output "Standard query failed, trying alternative approach..."
    try {
        # Alternative: Get all eligible roles and filter manually
        Write-Output "Retrieving all eligible roles..."
        $allRoles = Get-MgRoleManagementDirectoryRoleEligibilitySchedule -ExpandProperty RoleDefinition
        $eligibleRoles = $allRoles | Where-Object { $_.PrincipalId -eq $userId }
        Write-Output "Successfully retrieved role information using alternative method."
    } catch {
        Write-Error "Failed to retrieve eligible roles: $($_.Exception.Message)"
        Write-Output "This might indicate insufficient permissions for PIM role management."
        exit 1
    }
}

if (-not $eligibleRoles) {
    Write-Output "You have no eligible roles available."
    exit
}

# Display eligible roles
Write-Output "Available PIM roles:"
$roleChoices = $eligibleRoles | ForEach-Object -Begin { $i = 1 } -Process {
    $result = [PSCustomObject]@{
        Index = $i
        RoleName = $_.RoleDefinition.DisplayName
        RoleId = $_.RoleDefinition.Id
    }
    $i++
    $result
}

$roleChoices | Format-Table -AutoSize

# Select a role to activate
$selectedIndex = Read-Host "Enter the number of the role you want to activate"
$selectedRole = $roleChoices | Where-Object { $_.Index -eq [int]$selectedIndex }

if (-not $selectedRole) {
    Write-Output "Invalid selection. Exiting."
    exit
}

# Set activation duration (e.g., 2 hours)
$durationHours = 1
$startDateTime = (Get-Date).ToUniversalTime()
$endDateTime = $startDateTime.AddHours($durationHours)

# Request role activation
$params = @{
    Action = "selfActivate"
    Justification = "Activating via PowerShell script"
    PrincipalId = $userId
    RoleDefinitionId = $selectedRole.RoleId
    DirectoryScopeId = "/"
    ScheduleInfo = @{
        StartDateTime = $startDateTime
        EndDateTime = $endDateTime
    }
}

try {
    New-MgRoleManagementDirectoryRoleAssignmentScheduleRequest -BodyParameter $params
    Write-Output "Successfully requested activation of '$($selectedRole.RoleName)' role for $durationHours hour(s)."
} catch {
    Write-Error "Failed to request role activation: $($_.Exception.Message)"
    exit 1
}
