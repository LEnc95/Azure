# Microsoft Graph Authentication Fix Script
Write-Host "Microsoft Graph Authentication Fix" -ForegroundColor Magenta
Write-Host "=================================" -ForegroundColor Magenta

# Step 1: Check current module versions
Write-Host "`nStep 1: Checking module versions..." -ForegroundColor Yellow
try {
    $mgModule = Get-Module Microsoft.Graph -ListAvailable
    if ($mgModule) {
        Write-Host "Microsoft Graph module: $($mgModule.Version)" -ForegroundColor Green
    } else {
        Write-Host "Microsoft Graph module not found" -ForegroundColor Red
    }
} catch {
    Write-Host "Error checking Microsoft Graph module" -ForegroundColor Red
}

# Step 2: Clear existing connections
Write-Host "`nStep 2: Clearing existing connections..." -ForegroundColor Yellow
try {
    Disconnect-MgGraph -ErrorAction SilentlyContinue
    Write-Host "Cleared existing connections" -ForegroundColor Green
} catch {
    Write-Host "No existing connections to clear" -ForegroundColor Green
}

# Step 3: Update Microsoft Graph module
Write-Host "`nStep 3: Updating Microsoft Graph module..." -ForegroundColor Yellow
try {
    Write-Host "Installing/updating Microsoft Graph module..." -ForegroundColor Cyan
    Install-Module Microsoft.Graph -Force -AllowClobber -Scope CurrentUser -ErrorAction Stop
    Write-Host "Microsoft Graph module updated successfully" -ForegroundColor Green
} catch {
    Write-Host "Failed to update Microsoft Graph module: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "You may need to run PowerShell as Administrator" -ForegroundColor Yellow
}

# Step 4: Test basic connection
Write-Host "`nStep 4: Testing basic connection..." -ForegroundColor Yellow
try {
    Connect-MgGraph -Scopes 'User.Read' -ContextScope Process -ErrorAction Stop
    Write-Host "Basic connection successful" -ForegroundColor Green
    
    # Test a simple call
    $context = Get-MgContext
    if ($context) {
        Write-Host "Context verified: $($context.Account)" -ForegroundColor Green
    }
    
    Disconnect-MgGraph
    Write-Host "Disconnected successfully" -ForegroundColor Green
} catch {
    Write-Host "Basic connection failed: $($_.Exception.Message)" -ForegroundColor Red
}

# Step 5: Test with tenant-specific connection
Write-Host "`nStep 5: Testing tenant-specific connection..." -ForegroundColor Yellow
try {
    Connect-MgGraph -Scopes 'User.Read' -ContextScope Process -TenantId "gianteagle.com" -ErrorAction Stop
    Write-Host "Tenant-specific connection successful" -ForegroundColor Green
    
    # Test a simple call
    $context = Get-MgContext
    if ($context) {
        Write-Host "Context verified: $($context.Account)" -ForegroundColor Green
        Write-Host "Tenant: $($context.TenantId)" -ForegroundColor Green
    }
    
    Disconnect-MgGraph
    Write-Host "Disconnected successfully" -ForegroundColor Green
} catch {
    Write-Host "Tenant-specific connection failed: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "`nDiagnosis complete!" -ForegroundColor Cyan
Write-Host "If connections are working, try running your PIM script again." -ForegroundColor Cyan
Write-Host "If not, you may need to:" -ForegroundColor Yellow
Write-Host "1. Run PowerShell as Administrator" -ForegroundColor White
Write-Host "2. Check your internet connection" -ForegroundColor White
Write-Host "3. Verify your Azure AD permissions" -ForegroundColor White
Write-Host "4. Contact your IT administrator" -ForegroundColor White
