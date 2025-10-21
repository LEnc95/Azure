# Manual PIM Role Activation Guide

Since the PowerShell scripts are experiencing authentication issues, here's how to manually activate your PIM roles through the Azure Portal:

## Step-by-Step Manual Activation

### 1. Access Azure Portal
1. Open your web browser
2. Go to [https://portal.azure.com](https://portal.azure.com)
3. Sign in with your Giant Eagle credentials

### 2. Navigate to PIM
1. In the Azure Portal search bar, type "PIM" or "Privileged Identity Management"
2. Click on "Privileged Identity Management" from the results
3. You should see the PIM dashboard

### 3. View Your Eligible Roles
1. In the left navigation menu, click on "My roles"
2. You'll see a list of roles you're eligible for
3. Look for roles with "Eligible" status

### 4. Activate a Role
1. Find the role you want to activate
2. Click on "Activate" next to the role
3. Fill in the required information:
   - **Justification**: Enter why you need this role (e.g., "System maintenance", "Emergency access")
   - **Duration**: Select how long you need the role (usually 1-8 hours)
4. Click "Activate"

### 5. Verify Activation
1. After activation, the role status should change to "Active"
2. You can now perform tasks that require that role
3. The role will automatically expire after the specified duration

## Alternative: Use Azure CLI

If you prefer command-line tools, you can try Azure CLI instead of PowerShell:

### Install Azure CLI
1. Download from [https://docs.microsoft.com/en-us/cli/azure/install-azure-cli](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli)
2. Install and restart your terminal

### Login and Activate Roles
```bash
# Login to Azure
az login

# List your eligible role assignments
az rest --method GET --url "https://graph.microsoft.com/beta/roleManagement/directory/roleEligibilitySchedules?$filter=principalId eq 'YOUR_USER_ID'"

# Activate a role (replace with your specific role ID)
az rest --method POST --url "https://graph.microsoft.com/beta/roleManagement/directory/roleAssignmentScheduleRequests" --body '{
  "action": "selfActivate",
  "justification": "Activated via Azure CLI",
  "principalId": "YOUR_USER_ID",
  "roleDefinitionId": "ROLE_DEFINITION_ID",
  "directoryScopeId": "/",
  "scheduleInfo": {
    "startDateTime": "2024-01-01T00:00:00Z",
    "endDateTime": "2024-01-01T08:00:00Z"
  }
}'
```

## Troubleshooting PowerShell Issues

### Common Solutions:

1. **Update PowerShell Module**:
   ```powershell
   Install-Module Microsoft.Graph -Force -AllowClobber
   ```

2. **Run as Administrator**:
   - Right-click PowerShell and select "Run as Administrator"

3. **Check Execution Policy**:
   ```powershell
   Get-ExecutionPolicy
   Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
   ```

4. **Clear Module Cache**:
   ```powershell
   Remove-Module Microsoft.Graph -Force
   Import-Module Microsoft.Graph
   ```

5. **Use Different Authentication**:
   ```powershell
   Connect-MgGraph -UseDeviceAuthentication
   ```

## Contact IT Support

If none of these methods work, contact your IT administrator as there may be:
- Corporate firewall restrictions
- Azure AD tenant configuration issues
- PowerShell execution environment restrictions
- Network proxy settings blocking authentication

## Quick Reference

| Method | Pros | Cons |
|--------|------|------|
| Azure Portal | User-friendly, reliable | Manual process |
| Azure CLI | Command-line, scriptable | Requires installation |
| PowerShell | Most features | Authentication issues |

Choose the method that works best for your environment and requirements.
