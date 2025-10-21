# Azure AD Connection Guide

## Quick Connection Steps

### 1. Connect to Azure AD
```powershell
Connect-AzureAD
```
This will open a browser window for authentication.

### 2. Verify Connection
```powershell
Get-AzureADTenantDetail
```
This should return your tenant information.

### 3. Run Your Script
```powershell
.\Azure-AmazonDynamicGroupTest.ps1
```

## Troubleshooting

### If you get "Connect-AzureADPreview not recognized"
- Use `Connect-AzureAD` instead (the correct command)
- The AzureADPreview module uses the same connection commands as AzureAD

### If you get "module not found" errors
```powershell
# Install the AzureADPreview module (REQUIRED for dynamic group membership rules)
Install-Module AzureADPreview -Force

# Note: The regular AzureAD module does NOT support Set-AzureADMSGroup with -MembershipRule
# You MUST use AzureADPreview for updating dynamic group membership rules
```

### If you get permission errors
- Ensure you have Global Administrator or Group Administrator role
- Try running PowerShell as Administrator

## Connection Methods

### Method 1: Interactive (Recommended)
```powershell
Connect-AzureAD
```

### Method 2: With Credentials
```powershell
$Credential = Get-Credential
Connect-AzureAD -Credential $Credential
```

### Method 3: With Tenant ID
```powershell
Connect-AzureAD -TenantId "your-tenant-id-here"
```

## Script Execution Order

1. **Connect to Azure AD**: `Connect-AzureAD`
2. **Test first**: `.\Azure-AmazonDynamicGroupTest.ps1`
3. **Run batch**: `.\Azure-AmazonDynamicGroupCreation.ps1` or `.\Azure-AmazonDynamicGroupManagement.ps1`

## Notes

- All scripts now automatically attempt to connect if you're not already connected
- The scripts will show clear status messages about connection state
- If connection fails, the scripts will exit gracefully with instructions
