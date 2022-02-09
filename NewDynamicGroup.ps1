<#
STR groups request
#>
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

<#
foreach ($group in $groups) {
    #For each list table.
    $DisplayName = ""
    $Description = ""
    $MailNickName = ""

    foreach ($store in $stores) {
        #For each store in targeted table.

    }
    #Set Membership filter
    $MembershipRule = ""

    #Create new group
    New-AzureADMSGroup -DisplayName "$DisplayName" -Description "$Description" -MailEnabled $MailEnabled -MailNickName "$MailNickName" -SecurityEnabled $SecurityEnabled -GroupTypes "$GroupTypes" -MembershipRule "$MembershipRule" -MembershipRuleProcessingState "$MembershipRuleProcessingState"    
}
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

$DisplayName = ""
$Description = ""
$MailEnabled = $True
$MailNickName = ""
$SecurityEnabled = $True
$GroupTypes = "DynamicMembership"
$MembershipRule = ""
$MembershipRuleProcessingState = "On"

$DisplayName = "*SG*"
$MailNickName = "Test.Mail"
$MembershipRule = "user is X"

New-DynamicGroup $DisplayName $Description $MailNickName $MembershipRule
