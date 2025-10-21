# Fix Microsoft Graph Dependencies
Write-Host "Microsoft Graph Dependencies Fix" -ForegroundColor Magenta
Write-Host "=================================" -ForegroundColor Magenta

# Step 1: Check current modules
Write-Host "`nStep 1: Checking current Microsoft Graph modules..." -ForegroundColor Yellow
$mgModules = Get-Module Microsoft.Graph* -ListAvailable
if ($mgModules) {
    Write-Host "Found Microsoft Graph modules:" -ForegroundColor Green
    $mgModules | ForEach-Object { Write-Host "  - $($_.Name) v$($_.Version)" -ForegroundColor Cyan }
} else {
    Write-Host "No Microsoft Graph modules found" -ForegroundColor Red
}

# Step 2: Install missing authentication module
Write-Host "`nStep 2: Installing Microsoft Graph Authentication module..." -ForegroundColor Yellow
try {
    Install-Module Microsoft.Graph.Authentication -Force -AllowClobber -Scope CurrentUser -ErrorAction Stop
    Write-Host "Microsoft Graph Authentication module installed" -ForegroundColor Green
} catch {
    Write-Host "Failed to install Authentication module: $($_.Exception.Message)" -ForegroundColor Red
}

# Step 3: Install core Microsoft Graph module
Write-Host "`nStep 3: Installing core Microsoft Graph module..." -ForegroundColor Yellow
try {
    Install-Module Microsoft.Graph -Force -AllowClobber -Scope CurrentUser -ErrorAction Stop
    Write-Host "Microsoft Graph module installed" -ForegroundColor Green
} catch {
    Write-Host "Failed to install core module: $($_.Exception.Message)" -ForegroundColor Red
}

# Step 4: Install Identity module
Write-Host "`nStep 4: Installing Microsoft Graph Identity module..." -ForegroundColor Yellow
try {
    Install-Module Microsoft.Graph.Identity.DirectoryManagement -Force -AllowClobber -Scope CurrentUser -ErrorAction Stop
    Write-Host "Microsoft Graph Identity module installed" -ForegroundColor Green
} catch {
    Write-Host "Failed to install Identity module: $($_.Exception.Message)" -ForegroundColor Red
}

# Step 5: Test import
Write-Host "`nStep 5: Testing module import..." -ForegroundColor Yellow
try {
    Import-Module Microsoft.Graph -Force -ErrorAction Stop
    Write-Host "Microsoft Graph module imported successfully" -ForegroundColor Green
} catch {
    Write-Host "Failed to import module: $($_.Exception.Message)" -ForegroundColor Red
}

# Step 6: Test basic connection
Write-Host "`nStep 6: Testing basic connection..." -ForegroundColor Yellow
try {
    Connect-MgGraph -Scopes 'User.Read' -ErrorAction Stop
    Write-Host "Basic connection successful" -ForegroundColor Green
    
    $context = Get-MgContext
    if ($context) {
        Write-Host "Connected as: $($context.Account)" -ForegroundColor Green
    }
    
    Disconnect-MgGraph
    Write-Host "Disconnected successfully" -ForegroundColor Green
} catch {
    Write-Host "Connection test failed: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "`nFix completed!" -ForegroundColor Cyan
Write-Host "If the connection test passed, try running your PIM script again." -ForegroundColor Cyan
Write-Host "If it still fails, the issue may be with your corporate environment or network settings." -ForegroundColor Yellow
