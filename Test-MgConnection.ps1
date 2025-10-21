# Test Microsoft Graph Connection
# This script helps diagnose authentication issues

Write-Output "Microsoft Graph Connection Test"
Write-Output "================================"

# Check if Microsoft Graph module is installed
try {
    $mgModule = Get-Module Microsoft.Graph -ListAvailable
    if ($mgModule) {
        Write-Output "✓ Microsoft Graph module found: Version $($mgModule.Version)"
    } else {
        Write-Output "✗ Microsoft Graph module not found"
        Write-Output "Install with: Install-Module Microsoft.Graph -Force -AllowClobber"
        exit 1
    }
} catch {
    Write-Output "✗ Error checking Microsoft Graph module: $($_.Exception.Message)"
}

# Check current connection status
try {
    $context = Get-MgContext -ErrorAction SilentlyContinue
    if ($context) {
        Write-Output "✓ Currently connected to: $($context.TenantId)"
        Write-Output "  Account: $($context.Account)"
    } else {
        Write-Output "ℹ No active connection"
    }
} catch {
    Write-Output "ℹ No active connection"
}

# Test different authentication methods
Write-Output ""
Write-Output "Testing authentication methods..."
Write-Output "================================"

# Method 1: Tenant-specific authentication
Write-Output "Method 1: Tenant-specific authentication"
try {
    Connect-MgGraph -Scopes 'User.Read' -ContextScope Process -TenantId "gianteagle.com" -ErrorAction Stop
    Write-Output "✓ Tenant-specific authentication successful"
    
    # Test a simple call
    $testUser = Get-MgUser -UserId 'luke.encrapera@gianteagle.com' -ErrorAction Stop
    Write-Output "✓ Successfully retrieved user: $($testUser.DisplayName)"
    
    Disconnect-MgGraph
    Write-Output "✓ Disconnected successfully"
} catch {
    Write-Output "✗ Tenant-specific authentication failed: $($_.Exception.Message)"
}

Write-Output ""

# Method 2: Default authentication
Write-Output "Method 2: Default authentication"
try {
    Connect-MgGraph -Scopes 'User.Read' -ContextScope Process -ErrorAction Stop
    Write-Output "✓ Default authentication successful"
    
    # Test a simple call
    $testUser = Get-MgUser -UserId 'luke.encrapera@gianteagle.com' -ErrorAction Stop
    Write-Output "✓ Successfully retrieved user: $($testUser.DisplayName)"
    
    Disconnect-MgGraph
    Write-Output "✓ Disconnected successfully"
} catch {
    Write-Output "✗ Default authentication failed: $($_.Exception.Message)"
}

Write-Output ""
Write-Output "Test completed. Use the method that worked for your main script."
