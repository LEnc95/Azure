$DateTime = Get-Date -f "yyyy-MM" 

#Returns TRUE if the user has the license assigned directly
function UserHasLicenseAssignedDirectly
{
    Param([Microsoft.Online.Administration.User]$user, [string]$skuId)

    foreach($license in $user.Licenses)
    {
        #we look for the specific license SKU in all licenses assigned to the user
        if ($license.AccountSkuId -ieq $skuId)
        {
            #GroupsAssigningLicense contains a collection of IDs of objects assigning the license
            #This could be a group object or a user object (contrary to what the name suggests)
            #If the collection is empty, this means the license is assigned directly - this is the case for users who have never been licensed via groups in the past
            if ($license.GroupsAssigningLicense.Count -eq 0)
            {
                return $true
            }

            #If the collection contains the ID of the user object, this means the license is assigned directly
            #Note: the license may also be assigned through one or more groups in addition to being assigned directly
            foreach ($assignmentSource in $license.GroupsAssigningLicense)
            {
                if ($assignmentSource -ieq $user.ObjectId)
                {
                    return $true
                }
            }
            return $false
        }
    }
    return $false
}
#Returns TRUE if the user is inheriting the license from a group
function UserHasLicenseAssignedFromGroup
{
    Param([Microsoft.Online.Administration.User]$user, [string]$skuId)

    foreach($license in $user.Licenses)
    {
        #we look for the specific license SKU in all licenses assigned to the user
        if ($license.AccountSkuId -ieq $skuId)
        {
            #GroupsAssigningLicense contains a collection of IDs of objects assigning the license
            #This could be a group object or a user object (contrary to what the name suggests)
            foreach ($assignmentSource in $license.GroupsAssigningLicense)
            {
                #If the collection contains at least one ID not matching the user ID this means that the license is inherited from a group.
                #Note: the license may also be assigned directly in addition to being inherited
                if ($assignmentSource -ine $user.ObjectId)
                {
                    return $true
                }
            }
            return $false
        }
    }
    return $false
}

$filter = "UserPrincipalName -eq 'luke.encrapera@gianteagle.com' -or UserPrincipalName -eq '1196270@gianteagle.com' -or UserPrincipalName -eq '1220069@gianteagle.com'" #-or UserPrincipalName -eq 'Lori.Neil@gianteagle.com'
$users = Get-ADUser -Filter $filter -Properties * -SearchBase "DC=corp,DC=gianteagle,DC=com" |
 Select-Object objectGuid, SamAccountName, displayName, employeeType, Enabled, DistinguishedName, userPrincipalName 
 
$outputToFile = @("displayName;SamAccountName;employeeType;Enabled;UserPrincipalName;LicensedBy;DistinguishedName") 
foreach($user in $users){
    $groups = $null
    $groupNames = @()
    $direct = $null
    $license = (Get-MsolUser -UserPrincipalName $user.UserPrincipalName).licenses | Where-Object {$_.AccountSkuID -eq "gianteagle:SPE_F1" -or $_.AccountSkuID -eq "gianteagle:DESKLESSPACK"}
    If($license -ne $null){
        if ($license.GroupsAssigningLicense.Count -eq 0)
        {
            $groupNames += "DirectAssignment"
        }
        else
        {
            $groups = $license.GroupsAssigningLicense
            foreach($group in $groups){
                $groupNames += (Get-AzureADGroup -ObjectId $group.Guid).DisplayName
            }
        }
        $direct = UserHasLicenseAssignedDirectly
        $outputToFile += "$($user.displayName);$($user.SamAccountName);$($user.employeeType);$($user.Enabled);$($user.userPrincipalName);$($groupNames -join ', ');$($user.DistinguishedName)"
    }
    #$outputToFile += $output
}
#$outputToFile | Export-Csv -Path "C:\Temp\BasicLicenseReport.csv" -NoTypeInformation -Force
$outputToFile | Out-File -FilePath "C:\Temp\BasicLicenseReport.txt"