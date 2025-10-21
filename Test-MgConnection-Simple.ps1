# Simple Microsoft Graph Connection Test
Write-Host "Microsoft Graph Connection Test" -ForegroundColor Magenta
Write-Host "=================================" -ForegroundColor Magenta

# Test 1: Check if we can import the module
Write-Host "`nTest 1: Importing Microsoft Graph module..." -ForegroundColor Yellow
try {
    Import-Module Microsoft.Graph -ErrorAction Stop
    Write-Host "✓ Microsoft Graph module imported successfully" -ForegroundColor Green
} catch {
    Write-Host "✗ Failed to import Microsoft Graph module: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Test 2: Try the simplest possible connection
Write-Host "`nTest 2: Testing basic connection..." -ForegroundColor Yellow
try {
    Connect-MgGraph -Scopes 'User.Read' -ErrorAction Stop
    Write-Host "✓ Basic connection successful" -ForegroundColor Green
    
    # Test a simple call
    $context = Get-MgContext
    if ($context) {
        Write-Host "✓ Context verified: $($context.Account)" -ForegroundColor Green
        Write-Host "✓ Tenant: $($context.TenantId)" -ForegroundColor Green
    }
    
    Disconnect-MgGraph
    Write-Host "✓ Disconnected successfully" -ForegroundColor Green
} catch {
    Write-Host "✗ Basic connection failed: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "This indicates a fundamental issue with Microsoft Graph authentication." -ForegroundColor Yellow
}

# Test 3: Check PowerShell execution policy
Write-Host "`nTest 3: Checking PowerShell execution policy..." -ForegroundColor Yellow
$policy = Get-ExecutionPolicy
Write-Host "Current execution policy: $policy" -ForegroundColor Cyan
if ($policy -eq 'Restricted') {
    Write-Host "⚠ Warning: Execution policy is Restricted. This may cause issues." -ForegroundColor Yellow
    Write-Host "Consider running: Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser" -ForegroundColor Gray
}

# Test 4: Check if we're in a corporate environment
Write-Host "`nTest 4: Checking environment..." -ForegroundColor Yellow
Write-Host "User: $env:USERNAME" -ForegroundColor Cyan
Write-Host "Computer: $env:COMPUTERNAME" -ForegroundColor Cyan
Write-Host "Domain: $env:USERDOMAIN" -ForegroundColor Cyan

# Test 5: Check network connectivity
Write-Host "`nTest 5: Testing network connectivity..." -ForegroundColor Yellow
try {
    $response = Invoke-WebRequest -Uri "https://graph.microsoft.com" -Method Head -TimeoutSec 10 -ErrorAction Stop
    Write-Host "✓ Network connectivity to Microsoft Graph is working" -ForegroundColor Green
} catch {
    Write-Host "✗ Network connectivity issue: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "This may be due to corporate firewall or proxy settings." -ForegroundColor Yellow
}

Write-Host "`nDiagnosis complete!" -ForegroundColor Cyan
Write-Host "If all tests pass but authentication still fails, the issue may be:" -ForegroundColor Yellow
Write-Host "1. Corporate proxy/firewall blocking authentication" -ForegroundColor White
Write-Host "2. Microsoft Graph PowerShell module version compatibility" -ForegroundColor White
Write-Host "3. PowerShell execution environment restrictions" -ForegroundColor White
Write-Host "4. Azure AD tenant configuration" -ForegroundColor White
