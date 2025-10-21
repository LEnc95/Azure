# Amazon Dynamic Groups - Quick Start Guide

## 🚀 Which Script Do I Run?

### **START HERE** → Test Script
```powershell
.\Azure-AmazonDynamicGroupTest.ps1
```
- **What it does**: Tests with 1 store (store 0002 by default)
- **Safe**: Won't create groups unless you uncomment the creation code
- **Purpose**: Validate everything works before running batch operations

### **Then Choose One:**

#### Option A: Create NEW Groups
```powershell
.\Azure-AmazonDynamicGroupCreation.ps1
```
- **When to use**: You need to create Amazon groups for the first time
- **What it does**: Creates groups for all 170+ stores in your CSV
- **Result**: New groups like "Store 0002 - Amazon Delivery"

#### Option B: Update EXISTING Groups  
```powershell
.\Azure-AmazonDynamicGroupManagement.ps1
```
- **When to use**: You already have Amazon groups and want to update their rules
- **What it does**: Finds existing groups and updates their membership rules
- **Result**: Updated membership rules for existing groups

## 🔧 Quick Configuration

### Test Script Configuration
Edit line 12 in `Azure-AmazonDynamicGroupTest.ps1`:
```powershell
$testStore = "0002"  # Change to any store number from your CSV
```

### Excluded Stores
Edit the `$excludedLocations` array in any script to skip specific stores:
```powershell
$excludedLocations = @("9501", "1234")  # Add store numbers to exclude
```

## 📋 Step-by-Step Process

1. **Test First** (Always start here!)
   ```powershell
   .\Azure-AmazonDynamicGroupTest.ps1
   ```
   - Review the output
   - Check the generated membership rule
   - Verify logs in `C:\Temp\AmazonGroups\Test\`

2. **Choose Your Path**
   - **New Groups**: Run `Azure-AmazonDynamicGroupCreation.ps1`
   - **Existing Groups**: Run `Azure-AmazonDynamicGroupManagement.ps1`

3. **Verify Results**
   - Check Azure AD for the groups
   - Review logs in `C:\Temp\AmazonGroups\`
   - Test with a few users to ensure membership works

## 🛡️ Safety Features

- **Test Script**: Dry run mode by default (won't create groups)
- **Comprehensive Logging**: All actions logged with timestamps
- **Error Handling**: Scripts continue even if individual stores fail
- **Validation**: Membership rules are validated before application

## 📁 Log Locations

- **Test Script**: `C:\Temp\AmazonGroups\Test\`
- **Creation Script**: `C:\Temp\AmazonGroups\`
- **Management Script**: `C:\Temp\AmazonGroups\`

## ❓ Common Questions

**Q: Which script should I run first?**
A: Always start with `Azure-AmazonDynamicGroupTest.ps1`

**Q: Do I need to run both creation and management scripts?**
A: No, choose one based on your needs:
- New groups → Creation script
- Existing groups → Management script

**Q: What if I'm not sure?**
A: Run the test script first - it will show you what exists and what would be created

**Q: Can I run the test script multiple times?**
A: Yes, it's safe to run repeatedly for testing
