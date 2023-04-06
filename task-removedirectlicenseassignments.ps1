<#        
    .SYNOPSIS
     Remove any direct license assignments from a user.

    .DESCRIPTION
    Remove direct license assignments from users in Array
    report activity to csv in same dir as file is initiated. 
    .NOTES
    ========================================================================
         Windows PowerShell Source File 
         Created with Love
         
         NAME: Remove Direct License assignments
         
         AUTHOR: Encrapera, Luke 
         DATE  : 4/4/2023
         
         Modified: 4/6/2023
         COMMENT: N/A 
    ==========================================================================
#>

# Install required modules as current user (if you're not local admin) (only needed first time).
#Install-Module -Name DCToolbox -Scope CurrentUser -Force
#Install-Module -Name AzureADPreview -Scope CurrentUser -Force
#Install-Package msal.ps -Scope CurrentUser -Force
#Wait after checkout for success... unknown time needed. Immediate attempt will result in Access denied.
Enable-DCAzureADPIMRole -RolesToActivate "License Administrator" -Reason "Deprovisoining automation: REQ0000TEST" -UseMaximumTimeAllowed 

# Fetch all users
$UPN = @()
$UPN = 'Brian.shavensky@gianteagle.com'
$allUsers = Get-MsolUser -UserPrincipalName $UPN  #Get-MsolUser -All -ErrorAction Stop

# little report
$directLicenseAssignmentReport = @()
$directLicenseAssignmentCount = 0

foreach ($user in $allUsers){
    # processing all licenses per user
    foreach ($license in $user.Licenses){
        <#
            the "GroupsAssigningLicense" array contains objectId's of groups which inherit licenses
            if the array contains an entry with the users own objectId the license was assigned directly to the user
            if the array contains no entries and the user has a license assigned he also got a direct license assignment
        #>
        if ($license.GroupsAssigningLicense -contains $user.ObjectId -or $license.GroupsAssigningLicense.Count -lt 1){
           
            $directLicenseAssignmentCount++
            Write-Verbose "User $($user.UserPrincipalName) ($($user.ObjectId)) has direct license assignment for sku '$($license.AccountSkuId)')"
            
            # add details to the report
            $directLicenseAssignmentReport += [PSCustomObject]@{
                UserPrincipalName = $user.UserPrincipalName
                ObjectId = $user.ObjectId
                AccountSkuId = $license.AccountSkuId
                DirectAssignment = $true
            }

            if($license.AccountSkuId){
                Write-Warning "Removing license assignment for sku '$($license.AccountSkuId) on target '$($user.UserPrincipalName)'"
                Set-MsolUserLicense -ObjectId $user.ObjectId -RemoveLicenses $license.AccountSkuId
            }
        }
    }
}

if ($directLicenseAssignmentCount -gt 0){
    Write-Output "`nFound $directLicenseAssignmentCount direct assigned license(s):"
    Write-Output $directLicenseAssignmentReport

    $SaveReport = "True"
    if ($SaveReport -eq "True"){
        $exportPath = Join-Path $PSScriptRoot "AADDirectLicenseAssignments.csv"
        $directLicenseAssignmentReport | Export-Csv -Path $exportPath -Encoding "utf8" -NoTypeInformation -WhatIf:$false
        Write-Output "`nSaved report to: '$exportPath'"
    }

}else {
    Write-Output "No direct license assignments found"
}