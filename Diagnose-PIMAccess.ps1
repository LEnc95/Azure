# Diagnose PIM Access Issues
# This script helps identify why PIM role retrieval might be failing

Write-Output "PIM Access Diagnosis"
Write-Output "==================="

# Connect to Microsoft Graph
try {
    Write-Output "Connecting to Microsoft Graph..."
    Connect-MgGraph -Scopes 'RoleEligibilitySchedule.Read.Directory','RoleAssignmentSchedule.ReadWrite.Directory','Directory.Read.All' -ContextScope Process -TenantId "gianteagle.com"
    Write-Output "✓ Successfully connected to Microsoft Graph"
} catch {
    Write-Output "✗ Failed to connect: $($_.Exception.Message)"
    exit 1
}

# Check context
$context = Get-MgContext
Write-Output "Connected as: $($context.Account)"
Write-Output "Tenant: $($context.TenantId)"

# Test 1: Try to get current user
Write-Output ""
Write-Output "Test 1: Getting current user information"
try {
    $currentUser = Get-MgUser -UserId $context.Account
    Write-Output "✓ Current user: $($currentUser.DisplayName)"
    Write-Output "  User ID: $($currentUser.Id)"
} catch {
    Write-Output "✗ Failed to get current user: $($_.Exception.Message)"
}

# Test 2: Try to get specific user
Write-Output ""
Write-Output "Test 2: Getting specific user (luke.encrapera@gianteagle.com)"
try {
    $specificUser = Get-MgUser -UserId 'luke.encrapera@gianteagle.com'
    Write-Output "✓ Specific user: $($specificUser.DisplayName)"
    Write-Output "  User ID: $($specificUser.Id)"
} catch {
    Write-Output "✗ Failed to get specific user: $($_.Exception.Message)"
}

# Test 3: Try to get role eligibility schedules
Write-Output ""
Write-Output "Test 3: Getting role eligibility schedules"
try {
    $roles = Get-MgRoleManagementDirectoryRoleEligibilitySchedule -ExpandProperty RoleDefinition
    Write-Output "✓ Retrieved $($roles.Count) role eligibility schedules"
    
    if ($roles.Count -gt 0) {
        Write-Output "Sample roles:"
        $roles | Select-Object -First 3 | ForEach-Object {
            Write-Output "  - $($_.RoleDefinition.DisplayName) (Principal: $($_.PrincipalId))"
        }
    }
} catch {
    Write-Output "✗ Failed to get role eligibility schedules: $($_.Exception.Message)"
}

# Test 4: Check if user has any eligible roles
if ($specificUser) {
    Write-Output ""
    Write-Output "Test 4: Checking for user's eligible roles"
    try {
        $userRoles = Get-MgRoleManagementDirectoryRoleEligibilitySchedule -Filter "principalId eq '$($specificUser.Id)'" -ExpandProperty RoleDefinition
        Write-Output "✓ Found $($userRoles.Count) eligible roles for user"
        
        if ($userRoles.Count -gt 0) {
            Write-Output "User's eligible roles:"
            $userRoles | ForEach-Object {
                Write-Output "  - $($_.RoleDefinition.DisplayName)"
            }
        } else {
            Write-Output "ℹ User has no eligible roles"
        }
    } catch {
        Write-Output "✗ Failed to get user's eligible roles: $($_.Exception.Message)"
    }
}

Write-Output ""
Write-Output "Diagnosis complete. Check the results above to identify the issue."
