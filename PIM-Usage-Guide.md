# PIM Role Checkout Script Usage Guide

## Overview
The `PIMautomate.ps1` script allows you to view and activate your eligible PIM (Privileged Identity Management) roles in Entra ID.

## Basic Usage

### 1. Simple Interactive Mode
```powershell
. 'C:\Users\914476\Documents\Github\Azure\PIMautomate.ps1'
```
This will:
- Connect to Microsoft Graph
- Use your authenticated account
- Show your eligible roles
- Allow you to select and activate a role

### 2. List Only Mode
```powershell
. 'C:\Users\914476\Documents\Github\Azure\PIMautomate.ps1' -ListOnly
```
This will show your eligible roles without prompting for activation.

### 3. Specify User Email
```powershell
. 'C:\Users\914476\Documents\Github\Azure\PIMautomate.ps1' -UserEmail "user@gianteagle.com"
```

### 4. Custom Duration
```powershell
. 'C:\Users\914476\Documents\Github\Azure\PIMautomate.ps1' -DurationHours 2
```

### 5. Custom Justification
```powershell
. 'C:\Users\914476\Documents\Github\Azure\PIMautomate.ps1' -Justification "Emergency access for system maintenance"
```

### 6. Verbose Output
```powershell
. 'C:\Users\914476\Documents\Github\Azure\PIMautomate.ps1' -Verbose
```

## Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `-UserEmail` | String | "" | Email address of the user (if empty, uses authenticated account) |
| `-DurationHours` | Integer | 1 | Duration of role activation in hours |
| `-Justification` | String | "Activated via PowerShell script" | Justification for role activation |
| `-ListOnly` | Switch | False | Only list eligible roles, don't activate |
| `-Verbose` | Switch | False | Show detailed output |

## Features

### Authentication
- Multiple authentication methods with fallback
- Tenant-specific authentication for corporate environments
- Device code authentication as fallback

### Role Management
- View eligible PIM roles
- View currently active roles
- Interactive role selection
- Role activation with custom duration
- Custom justification for activation

### Error Handling
- Comprehensive error handling
- Clear error messages
- Fallback authentication methods
- Detailed troubleshooting information

## Examples

### Check roles for specific user
```powershell
. 'C:\Users\914476\Documents\Github\Azure\PIMautomate.ps1' -UserEmail "john.doe@gianteagle.com" -ListOnly
```

### Activate role for 4 hours with custom justification
```powershell
. 'C:\Users\914476\Documents\Github\Azure\PIMautomate.ps1' -DurationHours 4 -Justification "Database maintenance window"
```

### Verbose output for troubleshooting
```powershell
. 'C:\Users\914476\Documents\Github\Azure\PIMautomate.ps1' -Verbose
```

## Troubleshooting

### Authentication Issues
If you get authentication errors:
1. Update Microsoft Graph module:
   ```powershell
   Install-Module Microsoft.Graph -Force -AllowClobber
   ```
2. Clear existing connections:
   ```powershell
   Disconnect-MgGraph
   ```
3. Try running the script again

### Permission Issues
If you get permission errors:
- Ensure you have the necessary PIM permissions
- Check that your account has access to role management
- Verify you're connected to the correct tenant

### No Eligible Roles
If no eligible roles are found:
- Check that you have PIM roles assigned
- Verify the roles are eligible (not permanently active)
- Contact your administrator if roles should be available

## Security Notes

- Role activations are logged and auditable
- Always provide appropriate justification
- Use the minimum duration necessary
- Review active roles regularly
- Follow your organization's PIM policies
