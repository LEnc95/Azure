# Azure AD Management Scripts - API Documentation

## Overview

This repository contains a comprehensive collection of PowerShell scripts for managing Azure Active Directory, Office 365 licensing, dynamic groups, user accounts, and Multi-Factor Authentication (MFA). The scripts are designed to automate common administrative tasks in enterprise Azure environments.

## Prerequisites

### Required PowerShell Modules
- `AzureADPreview`
- `ActiveDirectory`
- `MSOnline`
- `ExchangeOnlineManagement`

### Required Permissions
- Azure AD Admin roles (Global Admin, User Admin, Groups Admin)
- Exchange Online Admin
- Active Directory permissions

## Core API Functions

### License Management APIs

#### `UserHasLicenseAssignedDirectly`
**Location:** `licenseAssignment.ps1`, `OfficeLicenseReporting_v2.ps1`, `removeDirectLicense.ps1`

```powershell
function UserHasLicenseAssignedDirectly {
    Param([Microsoft.Online.Administration.User]$user, [string]$skuId)
}
```

**Description:** Determines if a user has a specific license assigned directly (not through group membership).

**Parameters:**
- `$user` - Microsoft.Online.Administration.User object
- `$skuId` - License SKU identifier (e.g., "contoso:ENTERPRISEPACK")

**Returns:** Boolean - `$true` if license is directly assigned, `$false` otherwise

**Example:**
```powershell
$user = Get-MsolUser -UserPrincipalName "john.doe@company.com"
$hasDirectLicense = UserHasLicenseAssignedDirectly -user $user -skuId "contoso:ENTERPRISEPACK"
```

#### `UserHasLicenseAssignedFromGroup`
**Location:** `licenseAssignment.ps1`, `OfficeLicenseReporting_v2.ps1`

```powershell
function UserHasLicenseAssignedFromGroup {
    Param([Microsoft.Online.Administration.User]$user, [string]$skuId)
}
```

**Description:** Determines if a user has a specific license inherited from group membership.

**Parameters:**
- `$user` - Microsoft.Online.Administration.User object  
- `$skuId` - License SKU identifier

**Returns:** Boolean - `$true` if license is group-inherited, `$false` otherwise

**Example:**
```powershell
$user = Get-MsolUser -UserPrincipalName "jane.doe@company.com"
$hasGroupLicense = UserHasLicenseAssignedFromGroup -user $user -skuId "contoso:ENTERPRISEPACK"
```

#### `UserHasLicenseAssignedFromThisGroup`
**Location:** `removeDirectLicense.ps1`

```powershell
function UserHasLicenseAssignedFromThisGroup {
    Param([Microsoft.Online.Administration.User]$user, [string]$skuId, [Guid]$groupId)
}
```

**Description:** Checks if a user has a license assigned from a specific group.

**Parameters:**
- `$user` - Microsoft.Online.Administration.User object
- `$skuId` - License SKU identifier  
- `$groupId` - GUID of the specific group

**Returns:** Boolean

#### `GetUserLicense`
**Location:** `removeDirectLicense.ps1`

```powershell
function GetUserLicense {
    Param([Microsoft.Online.Administration.User]$user, [string]$skuId)
}
```

**Description:** Retrieves license information for a specific SKU assigned to a user.

**Parameters:**
- `$user` - Microsoft.Online.Administration.User object
- `$skuId` - License SKU identifier

**Returns:** License object or null

### Dynamic Group Management APIs

#### `New-DynamicGroup`
**Location:** `NewDynamicGroup.ps1`, `GetGoSTR/NewDynamicGroup.ps1`

```powershell
Function New-DynamicGroup() {
    Param(
        [Parameter(Mandatory = $true)] [string] $DisplayName,
        [Parameter(Mandatory = $false)] [string] $Description,
        [Parameter(Mandatory = $true)] [string] $MailNickName,
        [Parameter(Mandatory = $true)] [string] $MembershipRule
    )
}
```

**Description:** Creates a new Azure AD dynamic group with specified membership rules.

**Parameters:**
- `$DisplayName` (Mandatory) - Display name for the group
- `$Description` (Optional) - Group description
- `$MailNickName` (Mandatory) - Mail nickname for the group
- `$MembershipRule` (Mandatory) - Dynamic membership rule expression

**Example:**
```powershell
New-DynamicGroup -DisplayName "Sales Team" -Description "All sales department users" -MailNickName "salesteam" -MembershipRule "(user.department -eq 'Sales')"
```

#### `UpdateDynamicMembershipRule`
**Location:** `Azure-DynamicGroup-SetMembershipRule.ps1`

```powershell
Function UpdateDynamicMembershipRule {
    # Updates membership rules for multiple dynamic groups
}
```

**Description:** Updates membership rules for all configured dynamic groups in the store information hash table.

**Dependencies:** Requires `$storeInfo` hash table to be populated

#### `SearchADGroups`
**Location:** `Azure-DynamicGroup-SetMembershipRule.ps1`

```powershell
Function SearchADGroups {
    # Searches for Key Carrier groups
}
```

**Description:** Searches Active Directory for groups matching the Key Carriers pattern.

#### `ToConvertDynamicGroupToStatic`
**Location:** `ConvertDynamicGroupToStatic.ps1`

```powershell
function ToConvertDynamicGroupToStatic {
    # Converts dynamic groups to static groups
}
```

**Description:** Converts Azure AD dynamic groups to static groups by evaluating current membership.

### User Account Management APIs

#### `Get-SecretServerCredential`
**Location:** `inactiveUsersV2.ps1`, `InactiveUsers_PROD/*.ps1`

```powershell
function Get-SecretServerCredential {
    [cmdletbinding()]
    param(
        [parameter(ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            ValueFromRemainingArguments = $false,
            Position = 0)]
        [string[]]$ComputerName,
        [string]$SecretName,
        [int]$SecretID,
        [string]$SecretServerURL = "https://secretserver.corp.gianteagle.com/SecretServer/",
        [string]$SecretServerUsername,
        [string]$SecretServerPassword
    )
}
```

**Description:** Retrieves credentials from Secret Server for secure authentication.

**Parameters:**
- `$ComputerName` - Target computer names
- `$SecretName` - Name of the secret to retrieve
- `$SecretID` - ID of the secret to retrieve
- `$SecretServerURL` - Secret Server URL (defaults to corporate URL)
- `$SecretServerUsername` - Username for Secret Server
- `$SecretServerPassword` - Password for Secret Server

### Exchange Management APIs

#### `EXOP`
**Location:** `exop-enableremotemailbox.ps1`

```powershell
Function EXOP {
    # Enables remote mailbox functionality
}
```

**Description:** Enables Exchange Online remote mailbox for specified users.

### Cloud Account Management APIs

#### `Azure`
**Location:** `CloudAccountCheck.ps1`

```powershell
Function Azure {
    # Azure account management function
}
```

**Description:** Performs Azure account validation and management tasks.

#### `EXL`
**Location:** `CloudAccountCheck.ps1`

```powershell
function EXL($username,$param) {
    # Exchange Online management
}
```

**Description:** Manages Exchange Online user settings and configurations.

**Parameters:**
- `$username` - User principal name
- `$param` - Operation parameter

#### `ExchangeOnline`
**Location:** `CloudAccountCheck.ps1`

```powershell
function ExchangeOnline {
    # Exchange Online connection and management
}
```

**Description:** Establishes connection to Exchange Online and performs administrative tasks.

#### `License`
**Location:** `CloudAccountCheck.ps1`

```powershell
Function License($UPN) {
    # License management for specific user
}
```

**Description:** Manages license assignments for a specific user principal name.

**Parameters:**
- `$UPN` - User Principal Name

## Utility Functions

### License Analysis Functions

#### `GetDisabledPlansForSKU`
**Location:** `removeDirectLicense.ps1`

```powershell
function GetDisabledPlansForSKU {
    # Retrieves disabled service plans for a license SKU
}
```

**Description:** Returns a list of service plans that are disabled for a specific license SKU.

#### `GetUnexpectedEnabledPlansForUser`
**Location:** `removeDirectLicense.ps1`

```powershell
function GetUnexpectedEnabledPlansForUser {
    # Identifies unexpectedly enabled plans for a user
}
```

**Description:** Identifies service plans that are enabled for a user but should be disabled based on group policy.

## Configuration Variables

### Global Variables
- `$DateTime` - Current date/time formatting for file naming
- `$storeInfo` - Hash table containing store-to-group ID mappings
- `$DynamicGroupSet` - Array of dynamic groups for batch operations
- `$exclusion` - List of users excluded from automated processes
- `$OUs` - Organizational Units for user searches

### File Paths
- Output files typically saved to `C:\Temp\`
- Input files read from user's OneDrive GitHub directories
- CSV exports for reporting and audit trails

## Error Handling

Most functions implement try-catch blocks for error handling:

```powershell
try {
    # Main operation
}
catch {
    # Error handling and logging
}
```

## Authentication Patterns

### Azure AD Connection
```powershell
Import-Module AzureADPreview
Connect-AzureAD -Credential $Credential
```

### Exchange Online Connection
```powershell
Connect-ExchangeOnline -UserPrincipalName $UPN
```

### MSOnline Connection
```powershell
Connect-MsolService -Credential $cred
```

## Security Considerations

1. **Credential Management**: Use Secret Server for secure credential storage
2. **Least Privilege**: Ensure accounts have minimum required permissions
3. **Audit Logging**: All operations generate audit logs and reports
4. **Exclusion Lists**: Critical accounts protected via exclusion lists
5. **Testing**: Always test scripts in development environment first

## Common Usage Patterns

### License Management Workflow
1. Check current license assignment method
2. Identify direct vs. group-based assignments
3. Remove direct assignments where group-based exists
4. Generate reports for compliance

### Dynamic Group Workflow
1. Define membership rules based on user attributes
2. Create or update dynamic groups
3. Monitor membership changes
4. Generate reports for validation

### User Account Lifecycle
1. Identify inactive users based on last logon
2. Check Azure sign-in activity
3. Apply account expiration policies
4. Add to appropriate security groups
5. Generate compliance reports

## Support and Troubleshooting

### Common Issues
1. **Module Import Failures**: Ensure all required modules are installed
2. **Permission Errors**: Verify admin roles and permissions
3. **Connection Timeouts**: Check network connectivity and firewall rules
4. **Rate Limiting**: Implement delays between bulk operations

### Debugging
- Enable verbose logging: `$VerbosePreference = "Continue"`
- Use `-WhatIf` parameter for testing
- Check execution policies: `Get-ExecutionPolicy`
- Validate module versions: `Get-Module -ListAvailable`