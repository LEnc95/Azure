# Amazon Store Delivery Dynamic Groups

This directory contains PowerShell scripts for creating and managing dynamic Azure AD groups for Amazon store delivery locations.

## Scripts Overview

### 0. Azure-AmazonDynamicGroupTest.ps1 ⭐ **START HERE**
**Purpose**: Tests the Amazon delivery group creation process with a single store.

**Features**:
- Tests membership rule generation and validation
- Checks for existing groups
- Simulates group creation (dry run mode)
- Comprehensive test logging
- Safe testing environment

**Usage**:
```powershell
.\Azure-AmazonDynamicGroupTest.ps1
```

**Configuration**: Edit line 12 to change the test store number:
```powershell
$testStore = "0002"  # Change this to any store number from your CSV
```

### 1. Azure-AmazonDynamicGroupCreation.ps1
**Purpose**: Creates new Amazon delivery dynamic groups for all stores listed in the CSV file.

**Features**:
- Reads Amazon store locations from `Copy of Amazon ARK Expansion Locations.csv`
- Creates dynamic groups with naming convention: `{StoreNumber}_AmazonDelivery`
- Applies dynamic membership rules based on department and job codes
- Includes comprehensive logging and error handling
- Exports group information for reference

**Usage**:
```powershell
.\Azure-AmazonDynamicGroupCreation.ps1
```

### 2. Azure-AmazonDynamicGroupManagement.ps1
**Purpose**: Manages existing Amazon delivery dynamic groups and updates their membership rules.

**Features**:
- Finds existing Amazon groups in Active Directory
- Updates membership rules while preserving explicit additions
- Maintains the same job code filtering as the original CurbsideExpress script
- Comprehensive logging and error reporting

**Usage**:
```powershell
.\Azure-AmazonDynamicGroupManagement.ps1
```

## Recommended Workflow

### Step 1: Test First ⭐
```powershell
# 1. Run the test script with a single store
.\Azure-AmazonDynamicGroupTest.ps1

# 2. Review the test results and logs
# 3. Verify the membership rule looks correct
# 4. Check if any existing groups are updated properly
```

### Step 2: Create New Groups (if needed)
```powershell
# Only run this if you need to create NEW groups
.\Azure-AmazonDynamicGroupCreation.ps1
```

### Step 3: Manage Existing Groups
```powershell
# Run this to update existing Amazon groups
.\Azure-AmazonDynamicGroupManagement.ps1
```

## Prerequisites

1. **PowerShell Modules**:
   - **AzureADPreview module installed** (REQUIRED - regular AzureAD module does NOT support Set-AzureADMSGroup with -MembershipRule)
   - Active Directory module (for management script)

2. **Permissions**:
   - Azure AD Global Administrator or Group Administrator role
   - Active Directory read permissions (for management script)

3. **Files**:
   - `Copy of Amazon ARK Expansion Locations.csv` must be in the same directory as the creation script

## Dynamic Membership Rule

Both scripts use the same membership rule pattern:

```
(user.Department -contains "{StoreNumber}") -and (user.extensionAttribute3 -eq "A") -and ((user.extensionAttribute13 -In ["10147","10148","10180","31310","80119","80144","80155","80189","10183","88052","80246"]) -or (user.extensionAttribute6 -contains "10147") -or ...)
```

This rule includes users who:
- Have the store number in their Department field
- Have extensionAttribute3 set to "A" (active status)
- Have specific Amazon job codes in either extensionAttribute13 or extensionAttribute6

## Job Codes

The scripts use the following Amazon-specific job codes:
- 10147, 10148, 10180, 31310, 80119, 80144, 80155, 80189, 10183, 88052, 80246

## Logging

Both scripts create detailed logs in `C:\Temp\AmazonGroups\`:
- Creation/update timestamps
- Group IDs and membership rules
- Error details
- Summary reports

## Group Naming Convention

- **Display Name**: `Store {StoreNumber} - Amazon Delivery`
- **Group Name**: `{StoreNumber}_AmazonDelivery`
- **Description**: `Dynamic group for Amazon delivery at store {StoreNumber}`

## Error Handling

- Authentication checks with automatic reconnection prompts
- Graceful handling of existing groups
- Detailed error logging
- Continue processing even if individual stores fail

## Excluded Locations

Both scripts support excluding specific store locations from processing. Currently configured to exclude store "9501" (modify the `$excludedLocations` array as needed).

## CSV File Format

The CSV file should have a "Store" column with store numbers:
```csv
Store
0002
0004
0005
...
```

## Troubleshooting

1. **Authentication Issues**: Ensure you have proper Azure AD permissions
2. **Module Not Found**: Install AzureADPreview module: `Install-Module AzureADPreview`
3. **CSV Not Found**: Ensure the CSV file is in the correct location
4. **Permission Denied**: Check Azure AD group creation permissions
5. **"Set-AzureADMSGroup not recognized"**: You MUST use AzureADPreview module - regular AzureAD module does NOT support membership rule updates
6. **"Connect-AzureADPreview not recognized"**: Use `Connect-AzureAD` instead (AzureADPreview module uses the same connection commands)

## Related Scripts

- `Azure-DynamicGroupMembershipRuleExplicitAdditions.ps1` - Original CurbsideExpress management script
- `Copy of Amazon ARK Expansion Locations.csv` - Store locations data

## Notes

- Scripts are based on the existing CurbsideExpress pattern for consistency
- All groups are created as security-enabled, non-mail-enabled dynamic groups
- Membership rules are automatically enabled upon creation/update
- Scripts include comprehensive logging for audit purposes
