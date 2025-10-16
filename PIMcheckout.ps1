# Connect to Microsoft Graph using integrated Windows authentication
Connect-MgGraph -Scopes 'RoleEligibilitySchedule.Read.Directory','RoleAssignmentSchedule.ReadWrite.Directory','Directory.Read.All' -ContextScope Process

# Get your user ID automatically
$me = Get-MgUser -UserId 'luke.encrapera@gianteagle.com'
$userId = $me.Id

# Retrieve eligible roles
$eligibleRoles = Get-MgRoleManagementDirectoryRoleEligibilitySchedule -Filter "principalId eq '$userId'" -ExpandProperty RoleDefinition

if (-not $eligibleRoles) {
    Write-Output "You have no eligible roles available."
    exit
}

# Display eligible roles
Write-Output "Available PIM roles:"
$roleChoices = $eligibleRoles | ForEach-Object -Begin { $i = 1 } -Process {
    [PSCustomObject]@{
        Index = $i
        RoleName = $_.RoleDefinition.DisplayName
        RoleId = $_.RoleDefinition.Id
    }
    $i++
}

$roleChoices | Format-Table -AutoSize

# Select a role to activate
$selectedIndex = Read-Host "Enter the number of the role you want to activate"
$selectedRole = $roleChoices | Where-Object { $_.Index -eq [int]$selectedIndex }

if (-not $selectedRole) {
    Write-Output "Invalid selection. Exiting."
    exit
}

# Set activation duration (e.g., 2 hours)
$durationHours = 1
$startDateTime = (Get-Date).ToUniversalTime()
$endDateTime = $startDateTime.AddHours($durationHours)

# Request role activation
$params = @{
    Action = "selfActivate"
    Justification = "Activating via PowerShell script"
    PrincipalId = $userId
    RoleDefinitionId = $selectedRole.RoleId
    DirectoryScopeId = "/"
    ScheduleInfo = @{
        StartDateTime = $startDateTime
        EndDateTime = $endDateTime
    }
}

New-MgRoleManagementDirectoryRoleAssignmentScheduleRequest -BodyParameter $params

Write-Output "Requested activation of '$($selectedRole.RoleName)' role for $durationHours hour(s)."
