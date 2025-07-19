# PowerShell Scripts Reference Guide

## Core Management Scripts

### License Management Scripts

#### `licenseAssignment.ps1`
**Purpose:** Provides core functions for analyzing license assignment methods (direct vs. group-based).

**Key Functions:**
- `UserHasLicenseAssignedDirectly`
- `UserHasLicenseAssignedFromGroup`

**Usage:**
```powershell
# Import the functions
. .\licenseAssignment.ps1

# Check if user has direct license
$user = Get-MsolUser -UserPrincipalName "user@company.com"
$hasDirect = UserHasLicenseAssignedDirectly -user $user -skuId "contoso:ENTERPRISEPACK"
```

**Dependencies:** MSOnline module

---

#### `OfficeLicenseReporting_v2.ps1`
**Purpose:** Enhanced Office 365 license reporting with detailed assignment analysis.

**Features:**
- Direct vs. group license assignment detection
- Comprehensive license reporting
- Export to CSV format

**Usage:**
```powershell
.\OfficeLicenseReporting_v2.ps1
# Generates report in C:\Temp\ with timestamp
```

**Output:** CSV file with license assignment details

---

#### `removeDirectLicense.ps1`
**Purpose:** Advanced script for removing direct license assignments while preserving group-based assignments.

**Key Functions:**
- `UserHasLicenseAssignedFromThisGroup`
- `GetUserLicense`
- `GetDisabledPlansForSKU`
- `GetUnexpectedEnabledPlansForUser`

**Usage:**
```powershell
.\removeDirectLicense.ps1
# Safely removes direct assignments where group assignments exist
```

**Safety Features:**
- Validates group assignments before removal
- Comprehensive logging
- Rollback capabilities

---

#### `licensetrueup.ps1`
**Purpose:** Simple license true-up operations for compliance.

**Usage:**
```powershell
.\licensetrueup.ps1
```

---

### Dynamic Group Management Scripts

#### `NewDynamicGroup.ps1`
**Purpose:** Creates new Azure AD dynamic groups with advanced membership rules.

**Function:**
```powershell
New-DynamicGroup -DisplayName "IT Department" -Description "All IT users" -MailNickName "itdept" -MembershipRule "(user.department -eq 'IT')"
```

**Parameters:**
- `DisplayName` (Required): Group display name
- `Description` (Optional): Group description
- `MailNickName` (Required): Email alias
- `MembershipRule` (Required): Dynamic membership expression

**Example Membership Rules:**
```powershell
# Department-based
"(user.department -eq 'Sales')"

# Multi-condition
"(user.department -eq 'IT') -and (user.jobTitle -contains 'Manager')"

# Location-based
"(user.city -eq 'New York') -or (user.city -eq 'Boston')"
```

---

#### `UpdateDynamicGroups.ps1`
**Purpose:** Bulk update of dynamic group membership rules with comprehensive reporting.

**Features:**
- Batch processing of multiple groups
- Explicit user additions support
- Comprehensive audit reporting
- Store-based group management

**Configuration Variables:**
```powershell
$targetedGroups = @()  # Groups to update
$filterRule = ""       # New membership rule
```

**Usage:**
```powershell
# Configure target groups and rules
.\UpdateDynamicGroups.ps1
```

**Output Files:**
- `DynamicGroupSet_[timestamp].csv` - Group details
- `reportHash_[timestamp].txt` - Rule changes
- `reportStores_[timestamp].txt` - Affected stores
- `reportAdds_[timestamp].txt` - Explicit additions

---

#### `UpdateDynamicGroups2024.ps1`
**Purpose:** Updated version of dynamic group management for 2024 requirements.

**Enhancements:**
- Improved error handling
- Additional rule validation
- Enhanced reporting

---

#### `Azure-DynamicGroup-SetMembershipRule.ps1`
**Purpose:** Specialized script for setting membership rules on Key Carrier groups.

**Key Functions:**
- `UpdateDynamicMembershipRule`
- `SearchADGroups`
- `buildSet`
- `formatSet`

**Workflow:**
1. Search for Key Carrier groups in AD
2. Build dynamic group set from Azure AD
3. Format store information mapping
4. Apply new membership rules

**Usage:**
```powershell
.\Azure-DynamicGroup-SetMembershipRule.ps1
```

---

#### `Azure-DynamicGroupMembershipRuleExplicitAdditions.ps1`
**Purpose:** Manages explicit user additions to dynamic group membership rules.

**Features:**
- Credential-based authentication
- Explicit user email additions
- Rule modification and testing

**Usage:**
```powershell
.\Azure-DynamicGroupMembershipRuleExplicitAdditions.ps1
```

---

#### `ConvertDynamicGroupToStatic.ps1`
**Purpose:** Converts Azure AD dynamic groups to static groups while preserving membership.

**Function:**
```powershell
function ToConvertDynamicGroupToStatic {
    # Evaluates current dynamic membership
    # Creates static group with same members
    # Provides migration path
}
```

**Use Cases:**
- Migrating from dynamic to static groups
- Creating snapshots of dynamic membership
- Compliance requirements for static groups

---

### User Account Management Scripts

#### `inactiveUsersV2.ps1`
**Purpose:** Comprehensive inactive user management with Azure sign-in integration.

**Features:**
- 90-day on-premises inactivity detection
- 30-day Azure sign-in verification
- Account expiration automation
- Security group management
- Exclusion list support

**Configuration:**
```powershell
$OUs = "OU=Contractors,OU=Users...", "OU=Corporate Users,OU=Users..."
$exclusion = Get-Content -Path "inactiveExclusion.txt"
```

**Workflow:**
1. Scan specified OUs for inactive users
2. Cross-reference with Azure sign-in logs
3. Apply account expiration for truly inactive accounts
4. Add to SG_Expired_Accounts group
5. Generate comprehensive reports

**Usage:**
```powershell
.\inactiveUsersV2.ps1
```

**Output:** Detailed CSV reports with user activity analysis

---

#### `account_review.ps1`
**Purpose:** Account review and audit functionality.

**Usage:**
```powershell
.\account_review.ps1
```

---

#### `CloudAccountCheck.ps1`
**Purpose:** Comprehensive cloud account validation and management.

**Key Functions:**
- `Azure` - Azure account operations
- `EXL` - Exchange Online management
- `ExchangeOnline` - Connection management
- `License` - User license management

**Multi-Service Integration:**
- Azure AD
- Exchange Online
- MSOnline Service

**Usage:**
```powershell
.\CloudAccountCheck.ps1
```

---

### MFA and Security Scripts

#### `Report_MFA_Enrollment.ps1`
**Purpose:** Generate detailed MFA enrollment reports for specific departments.

**Features:**
- Department-based filtering
- MFA method detection
- Admin user identification
- Contact information reporting

**Configuration:**
```powershell
$users = get-aduser -Filter {department -like "6376"}
```

**MFA Methods Detected:**
- SMS token
- Phone call verification
- Workphone call verification
- Hardware token or authenticator app
- Authenticator app

**Output Fields:**
- DisplayName
- UserPrincipalName
- isAdmin
- MFAType
- MFAEnforced
- Email Verification
- Registered phone

**Usage:**
```powershell
.\Report_MFA_Enrollment.ps1
```

**Output:** `C:\Temp\MFAEnrollment.csv`

---

#### `MSOL-StrongAuthenticationMethods.ps1`
**Purpose:** Manage strong authentication methods for users.

**Usage:**
```powershell
.\MSOL-StrongAuthenticationMethods.ps1
```

---

#### `Clean up phone authentication method.ps1`
**Purpose:** Clean up and manage phone authentication methods.

**Features:**
- Microsoft Graph integration
- Delegated authentication
- Phone number management

**Usage:**
```powershell
.\Clean\ up\ phone\ authentication\ method.ps1
```

---

### Password Policy Scripts

#### `checkPassPol_inSync.ps1`
**Purpose:** Compare and synchronize password policies between on-premises and cloud.

**Features:**
- Policy comparison analysis
- Synchronization status reporting
- Compliance validation

**Output Files:**
- `checkPassPol_inSync.csv` - Detailed comparison results
- `checkPassPol_inSync.txt` - Summary report

**Usage:**
```powershell
.\checkPassPol_inSync.ps1
```

---

#### `ComparePasswordPolicies.ps1`
**Purpose:** Advanced password policy comparison tool.

**Dependencies:**
- ActiveDirectory module
- AzureAD module (commented)

**Usage:**
```powershell
.\ComparePasswordPolicies.ps1
```

---

#### `passwordExpirationCheck.ps1`
**Purpose:** Check and report on password expiration status.

**Features:**
- MSOnline integration
- Expiration date analysis
- User notification capabilities

**Usage:**
```powershell
.\passwordExpirationCheck.ps1
```

---

#### `passpol_XRX.ps1`
**Purpose:** Xerox-specific password policy management.

**Dependencies:**
- ActiveDirectory module
- AzureAD module

**Usage:**
```powershell
.\passpol_XRX.ps1
```

---

### Search and Reporting Scripts

#### `Azure-GroupSearch.ps1`
**Purpose:** Search Azure AD groups with advanced filtering.

**Usage:**
```powershell
.\Azure-GroupSearch.ps1
```

---

#### `Find Azure users by Primary Job Code.ps1`
**Purpose:** Find Azure users based on primary job code attributes.

**Usage:**
```powershell
.\Find\ Azure\ users\ by\ Primary\ Job\ Code.ps1
```

---

#### `Report service desk accounts.ps1`
**Purpose:** Generate reports on service desk account status.

**Dependencies:** ActiveDirectory module

**Usage:**
```powershell
.\Report\ service\ desk\ accounts.ps1
```

---

#### `ADusers_ReturnAzureData.ps1`
**Purpose:** Return Azure data for Active Directory users.

**Usage:**
```powershell
.\ADusers_ReturnAzureData.ps1
```

---

### License Assignment Automation Scripts

#### `AssignLicenseMembership-ProjectPlanP1.ps1`
**Purpose:** Automated license assignment for Project Plan P1.

**Usage:**
```powershell
.\AssignLicenseMembership-ProjectPlanP1.ps1
```

---

#### `Remove Direct license assignment MSOL.ps1`
**Purpose:** Remove direct license assignments using MSOnline.

**Usage:**
```powershell
.\Remove\ Direct\ license\ assignment\ MSOL.ps1
```

---

#### `task-removedirectlicenseassignments.ps1`
**Purpose:** Task automation for removing direct license assignments.

**Features:**
- Comprehensive documentation (SYNOPSIS)
- Automated workflow
- Error handling

**Usage:**
```powershell
.\task-removedirectlicenseassignments.ps1
```

---

### Utility and Configuration Scripts

#### `ConnectAzureAD_Try-Catch.ps1`
**Purpose:** Robust Azure AD connection with error handling.

**Features:**
- Try-catch error handling
- Credential validation
- Connection status verification

**Usage:**
```powershell
.\ConnectAzureAD_Try-Catch.ps1
```

---

#### `Import-Module AzureADPreview.ps1`
**Purpose:** Import AzureADPreview module with error handling.

**Usage:**
```powershell
.\Import-Module\ AzureADPreview.ps1
```

---

#### `Get-DisablePasswordExpiration.ps1`
**Purpose:** Manage password expiration settings.

**Usage:**
```powershell
.\Get-DisablePasswordExpiration.ps1
```

---

### Exchange and Mailbox Scripts

#### `exop-enableremotemailbox.ps1`
**Purpose:** Enable Exchange Online remote mailboxes.

**Function:**
```powershell
Function EXOP {
    # Remote mailbox enablement
}
```

**Usage:**
```powershell
.\exop-enableremotemailbox.ps1
```

---

### Stale Account Management

#### `Manage stale Azure AD accounts.ps1`
**Purpose:** Identify and manage stale Azure AD accounts.

**Usage:**
```powershell
.\Manage\ stale\ Azure\ AD\ accounts.ps1
```

---

### Attribute Management Scripts

#### `Update_ExtensionAttribute1_PROD.ps1`
**Purpose:** Update extension attribute 1 in production environment.

**Usage:**
```powershell
.\Update_ExtensionAttribute1_PROD.ps1
```

---

#### `UpdatePasswordPolicy_GenericAcc.ps1`
**Purpose:** Update password policies for generic accounts.

**Dependencies:**
- AzureAD module (commented)
- Credential management

**Usage:**
```powershell
.\UpdatePasswordPolicy_GenericAcc.ps1
```

---

## Directory-Specific Scripts

### SSPR Directory

#### `SSPR/sspr.ps1`
**Purpose:** Self-Service Password Reset functionality.

**File Size:** 560B (11 lines)

**Usage:**
```powershell
.\SSPR\sspr.ps1
```

---

### GetGoSTR Directory

#### `GetGoSTR/NewDynamicGroup.ps1`
**Purpose:** Store-specific dynamic group creation.

**File Size:** 4.7KB (121 lines)

#### `GetGoSTR/setSMTP.ps1`
**Purpose:** SMTP configuration management.

**Features:**
- Exchange Online integration (commented)
- SMTP settings configuration

**File Size:** 511B (8 lines)

**Usage:**
```powershell
.\GetGoSTR\setSMTP.ps1
```

---

### InactiveUsers_PROD Directory

Contains production versions of inactive user management scripts:

- `InactiveUsers_PROD.ps1` - Production inactive user management
- `InactiveUsers_DEV.ps1` - Development version
- `inactiveUsers_DEV-v3.ps1` - Version 3 development
- `splunk_results.ps1` - Splunk integration

All contain `Get-SecretServerCredential` function for secure authentication.

---

## Common Usage Patterns

### Script Execution Order for License Management
1. `licenseAssignment.ps1` - Analyze current state
2. `OfficeLicenseReporting_v2.ps1` - Generate reports
3. `removeDirectLicense.ps1` - Clean up assignments
4. `task-removedirectlicenseassignments.ps1` - Automate cleanup

### Dynamic Group Management Workflow
1. `NewDynamicGroup.ps1` - Create new groups
2. `UpdateDynamicGroups.ps1` - Update existing rules
3. `Azure-DynamicGroup-SetMembershipRule.ps1` - Apply specific rules
4. Validation and reporting

### User Lifecycle Management
1. `inactiveUsersV2.ps1` - Identify inactive users
2. `CloudAccountCheck.ps1` - Validate cloud accounts
3. `Report_MFA_Enrollment.ps1` - Check MFA status
4. Account action and reporting

## Security Best Practices

### Credential Management
- Use `Get-SecretServerCredential` for secure authentication
- Store credentials in Secret Server
- Use service accounts with appropriate permissions

### Testing and Validation
- Test scripts in development environment first
- Use `-WhatIf` parameters where available
- Generate reports before making changes
- Maintain exclusion lists for critical accounts

### Logging and Auditing
- All scripts generate timestamped output files
- Export results to CSV for audit trails
- Monitor execution logs for errors
- Maintain change documentation

## Dependencies and Prerequisites

### PowerShell Modules Required
```powershell
Install-Module AzureADPreview
Install-Module MSOnline
Install-Module ActiveDirectory
Install-Module ExchangeOnlineManagement
```

### Permissions Required
- Azure AD administrative roles
- Exchange Online admin rights
- Active Directory permissions
- Secret Server access

### Network Requirements
- Access to Azure endpoints
- Exchange Online connectivity
- Active Directory domain connectivity
- Secret Server access