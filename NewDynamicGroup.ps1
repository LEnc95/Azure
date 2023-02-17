<#        
    .SYNOPSIS

    .DESCRIPTION

    .NOTES
    ========================================================================
         Windows PowerShell Source File 
         Created with Love
         
         NAME: 
         
         AUTHOR: Encrapera, Luke 
         DATE  : 0/0/2021
         
         COMMENT:  
         
    ==========================================================================
#>

Function New-DynamicGroup()
{
    # Create multiple parameters
    # Mandatory parameter, set true
    # Optional parameter, set false
    # string data type and parameter name

    Param
    (
        [Parameter(Mandatory = $true)] [string] $DisplayName,
        [Parameter(Mandatory = $false)] [string] $Description,
        [Parameter(Mandatory = $true)] [string] $MailNickName,
        [Parameter(Mandatory = $true)] [string] $MembershipRule
    )

    try 
     {
                    # Check if group exists
                    if(Get-ADGroup -Filter {Name -like $DisplayName} -ErrorAction Ignore)
                    {
                        Write-Host "$_.DisplayName already exists in Active Directory"
                    }
                    else {
                        #New-AzureADMSGroup -DisplayName "$DisplayName" -Description "$Description" -MailEnabled $MailEnabled -MailNickName "$MailNickName" -SecurityEnabled $SecurityEnabled -GroupTypes "$GroupTypes" -MembershipRule "$MembershipRule" -MembershipRuleProcessingState "$MembershipRuleProcessingState"
                        $DisplayName, $MembershipRule
                    }

        }
        catch
        {
             $ErrorMsg = $_.Exception.Message + " error raised while creating group!"
             Write-Host $ErrorMsg -BackgroundColor Red
        }
    
}
#Optional
$Description = ""
$MailEnabled = $True
$SecurityEnabled = $True
$GroupTypes = "DynamicMembership"
$MembershipRuleProcessingState = "On"
#Required
$DisplayName = "DEPT"+"_GROUPNAME"
$MailNickName = "Test.Mail"
$MembershipRule = "user is X"

#Set of Departments
$Departments = @()
#For Each department create a new ADMS group
$Departments | ForEach-Object {
    #New-DynamicGroup $DisplayName $Description $MailNickName $MembershipRule
}
