# Azure AD Management Scripts Collection

A comprehensive PowerShell script library for managing Azure Active Directory, Office 365 licensing, dynamic groups, user accounts, and Multi-Factor Authentication in enterprise environments.

## 📚 Documentation

This repository includes comprehensive documentation for all public APIs, functions, and components:

- **[API Documentation](API_DOCUMENTATION.md)** - Complete API reference for all public functions
- **[Script Reference](SCRIPT_REFERENCE.md)** - Individual script documentation with usage instructions  
- **[Usage Examples](USAGE_EXAMPLES.md)** - Practical scenarios and step-by-step examples

## 🏗️ Repository Structure

### Core Management Areas

#### 🏷️ License Management
- **Primary Scripts**: `licenseAssignment.ps1`, `OfficeLicenseReporting_v2.ps1`, `removeDirectLicense.ps1`
- **Purpose**: Analyze, report, and manage Office 365 license assignments
- **Key Features**: Direct vs. group-based license detection, automated cleanup, compliance reporting

#### 👥 Dynamic Group Management  
- **Primary Scripts**: `NewDynamicGroup.ps1`, `UpdateDynamicGroups.ps1`, `Azure-DynamicGroup-SetMembershipRule.ps1`
- **Purpose**: Create and manage Azure AD dynamic groups with rule-based membership
- **Key Features**: Bulk operations, store-based management, membership rule updates

#### 👤 User Account Lifecycle
- **Primary Scripts**: `inactiveUsersV2.ps1`, `CloudAccountCheck.ps1`, `account_review.ps1`
- **Purpose**: Monitor user activity, manage account lifecycle, validate cloud accounts
- **Key Features**: Inactivity detection, Azure sign-in integration, automated expiration

#### 🔐 MFA and Security
- **Primary Scripts**: `Report_MFA_Enrollment.ps1`, `MSOL-StrongAuthenticationMethods.ps1`
- **Purpose**: Monitor and manage Multi-Factor Authentication enrollment
- **Key Features**: Department-based reporting, method analysis, security compliance

#### 🔑 Password Policy Management
- **Primary Scripts**: `checkPassPol_inSync.ps1`, `ComparePasswordPolicies.ps1`, `passwordExpirationCheck.ps1`
- **Purpose**: Synchronize and monitor password policies between on-premises and cloud
- **Key Features**: Policy comparison, compliance validation, expiration management

## 🚀 Quick Start

### Prerequisites

#### Required PowerShell Modules
```powershell
Install-Module AzureADPreview -Force
Install-Module MSOnline -Force  
Install-Module ActiveDirectory -Force
Install-Module ExchangeOnlineManagement -Force
```

#### Required Permissions
- Azure AD administrative roles (Global Admin, User Admin, Groups Admin)
- Exchange Online administrative access
- Active Directory read/write permissions
- Secret Server access for credential management

### Basic Usage Examples

#### Check User License Assignment
```powershell
# Import license functions
. .\licenseAssignment.ps1

# Connect and check user
Connect-MsolService
$user = Get-MsolUser -UserPrincipalName "user@company.com"
$hasDirectLicense = UserHasLicenseAssignedDirectly -user $user -skuId "contoso:ENTERPRISEPACK"
```

#### Create Dynamic Group
```powershell
# Import and connect
. .\NewDynamicGroup.ps1
Import-Module AzureADPreview
Connect-AzureAD

# Create department-based group
New-DynamicGroup -DisplayName "IT-Managers" -Description "IT Department Managers" -MailNickName "itmanagers" -MembershipRule "(user.department -eq 'IT') -and (user.jobTitle -contains 'Manager')"
```

#### Generate MFA Report
```powershell
# Execute MFA enrollment report
.\Report_MFA_Enrollment.ps1

# Analyze results
$mfaData = Import-Csv "C:\Temp\MFAEnrollment.csv"
$enrolledUsers = $mfaData | Where-Object { $_.MFAType -ne "" }
Write-Host "MFA Enrollment Rate: $([math]::Round(($enrolledUsers.Count / $mfaData.Count) * 100, 2))%"
```

## 📋 Core Functions Reference

### License Management APIs
| Function | Purpose | Location |
|----------|---------|----------|
| `UserHasLicenseAssignedDirectly` | Check direct license assignments | `licenseAssignment.ps1` |
| `UserHasLicenseAssignedFromGroup` | Check group-based assignments | `licenseAssignment.ps1` |
| `GetUserLicense` | Retrieve license details | `removeDirectLicense.ps1` |

### Dynamic Group APIs
| Function | Purpose | Location |
|----------|---------|----------|
| `New-DynamicGroup` | Create dynamic groups | `NewDynamicGroup.ps1` |
| `UpdateDynamicMembershipRule` | Update group rules | `Azure-DynamicGroup-SetMembershipRule.ps1` |
| `ToConvertDynamicGroupToStatic` | Convert to static groups | `ConvertDynamicGroupToStatic.ps1` |

### User Management APIs
| Function | Purpose | Location |
|----------|---------|----------|
| `Get-SecretServerCredential` | Secure credential retrieval | `inactiveUsersV2.ps1` |
| `Azure` | Azure account operations | `CloudAccountCheck.ps1` |
| `License` | User license management | `CloudAccountCheck.ps1` |

## 🔧 Configuration

### Global Variables
- `$DateTime` - Timestamp formatting for file naming
- `$storeInfo` - Store-to-group ID mappings  
- `$exclusion` - Protected user accounts list
- `$OUs` - Target Organizational Units

### Default File Paths
- **Output Directory**: `C:\Temp\`
- **Input Files**: User's OneDrive GitHub directories
- **Reports**: CSV format with timestamps
- **Logs**: Detailed execution logs

## 📊 Reporting and Output

### Standard Report Types
- **License Reports**: Assignment analysis, compliance status
- **MFA Reports**: Enrollment status, method distribution
- **User Activity**: Sign-in analysis, inactive accounts
- **Group Membership**: Dynamic rule evaluation, changes
- **Password Policy**: Synchronization status, compliance

### Output Formats
- CSV files for data analysis
- JSON summaries for automation
- TXT logs for troubleshooting
- Timestamped files for audit trails

## 🔒 Security Best Practices

### Credential Management
- Use Secret Server for secure authentication
- Implement service accounts with least privilege
- Store sensitive data in protected locations
- Regular credential rotation

### Testing and Validation  
- Test all scripts in development environment first
- Use `-WhatIf` parameters where available
- Maintain exclusion lists for critical accounts
- Generate reports before making changes

### Audit and Compliance
- All operations generate timestamped logs
- CSV exports provide audit trails  
- Monitor execution for errors
- Document all changes and exceptions

## 🏢 Enterprise Features

### Bulk Operations
- Process multiple users simultaneously
- Batch dynamic group updates
- Automated license cleanup workflows
- Comprehensive health checks

### Integration Points
- Azure AD and Office 365
- On-premises Active Directory
- Exchange Online
- Secret Server
- Splunk (for some scripts)

### Automation Support
- Scheduled task compatibility
- Error handling and recovery
- Progress reporting
- Parallel processing capabilities

## 📁 Directory Structure

```
├── README.md                          # This file
├── API_DOCUMENTATION.md               # Complete API reference
├── SCRIPT_REFERENCE.md                # Individual script documentation
├── USAGE_EXAMPLES.md                  # Practical examples and scenarios
├── 
├── License Management/
│   ├── licenseAssignment.ps1          # Core license functions
│   ├── OfficeLicenseReporting_v2.ps1  # Enhanced reporting
│   ├── removeDirectLicense.ps1        # Safe license removal
│   └── task-removedirectlicenseassignments.ps1
│
├── Dynamic Groups/
│   ├── NewDynamicGroup.ps1            # Group creation
│   ├── UpdateDynamicGroups.ps1        # Bulk updates
│   ├── Azure-DynamicGroup-SetMembershipRule.ps1
│   └── ConvertDynamicGroupToStatic.ps1
│
├── User Management/
│   ├── inactiveUsersV2.ps1            # Inactive user processing
│   ├── CloudAccountCheck.ps1          # Account validation
│   └── InactiveUsers_PROD/            # Production versions
│
├── MFA and Security/
│   ├── Report_MFA_Enrollment.ps1      # MFA reporting
│   ├── MSOL-StrongAuthenticationMethods.ps1
│   └── Clean up phone authentication method.ps1
│
├── Password Management/
│   ├── checkPassPol_inSync.ps1        # Policy synchronization
│   ├── ComparePasswordPolicies.ps1    # Policy comparison
│   └── passwordExpirationCheck.ps1    # Expiration monitoring
│
└── Utilities/
    ├── ConnectAzureAD_Try-Catch.ps1   # Connection helpers
    ├── SSPR/                          # Self-service password reset
    └── GetGoSTR/                      # Store-specific tools
```

## 🆘 Support and Troubleshooting

### Common Issues
1. **Module Import Failures**: Ensure all required PowerShell modules are installed
2. **Permission Errors**: Verify administrative roles and permissions
3. **Connection Timeouts**: Check network connectivity and firewall rules
4. **Rate Limiting**: Implement appropriate delays between bulk operations

### Debugging Tips
- Enable verbose logging: `$VerbosePreference = "Continue"`
- Check execution policies: `Get-ExecutionPolicy`
- Validate module versions: `Get-Module -ListAvailable`
- Review generated log files for detailed error information

### Getting Help
1. Check the comprehensive documentation files
2. Review usage examples for similar scenarios
3. Examine generated log files for specific errors
4. Verify all prerequisites and permissions

## 📄 License

See [LICENSE](LICENSE) file for licensing information.

## 🤝 Contributing

This is an enterprise Azure AD management toolkit. For modifications or enhancements:

1. Test thoroughly in development environment
2. Follow existing coding patterns and documentation standards
3. Update relevant documentation files
4. Ensure backward compatibility
5. Add appropriate error handling and logging

---

**⚠️ Important**: Always test scripts in a development environment before running in production. These scripts can make significant changes to Azure AD configurations. 

