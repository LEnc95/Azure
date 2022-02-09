<#        
    .SYNOPSIS
    Create new Azure ADMS group

    .DESCRIPTION
    Iterate through csv files in src/ file path.
    For each CSV use file name and parse to create group name. 
    Get file contents which is a collection of stores and excess data. 
    Format Stores in CSV for use in Azure AD Dynamic group filter. Build filter and create group.
    Function checks for existing group and will ignore if group already exist in Azure.

    .NOTES
    ========================================================================
         Windows PowerShell Source File 
         Created with Love
         
         NAME: STR groups request | NewAzureADMSDynamicGroup
         
         AUTHOR: Encrapera, Luke 
         DATE  : 10/28/2021
         
         COMMENT: For usage or assistance: Luke.Encrapera@gianteagle.com 
         
    ==========================================================================
#>
Function New-DynamicGroup() {
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

    try {
        # Check if group exists
        if (Get-ADGroup -Filter { Name -like $DisplayName } -ErrorAction Ignore) {
                        
        }
        else {
            #New-AzureADMSGroup -DisplayName "$DisplayName" -Description "$Description" -MailEnabled $false <#$MailEnabled#> -MailNickName "$MailNickName" -SecurityEnabled $true <#$SecurityEnabled#> -GroupTypes "$GroupTypes" -MembershipRule "$MembershipRule" -MembershipRuleProcessingState "$MembershipRuleProcessingState"
            $DisplayName#, $Description, $MailNickName, $MembershipRule
        }

    }
    catch {
        $ErrorMsg = $_.Exception.Message + " error raised while creating group!"
        Write-Host $ErrorMsg -BackgroundColor Red
    }
    
}

$mypath = $MyInvocation.MyCommand.Path
$parentDir = Split-Path $mypath -Parent

$GroupName = @()
$StoresList = @()

$DisplayName = ""
$Description = ""
$MailEnabled = $True
$MailNickName = ""
$SecurityEnabled = $False
$GroupTypes = "DynamicMembership"
$MembershipRule = ""
$MembershipRuleProcessingState = "On"

#$DisplayName = "*SG*"
#$MailNickName = "Test.Mail"
#$MembershipRule = "user is X"

$inFile = Get-ChildItem  "$parentDir/src/"
$inFile | foreach-object {
    $GroupName = @()
    $StoresList = @()
    $GroupName += $_.Name.split(".")[0]
    $StoresList += (Get-Content "$parentDir/src/$($_.Name)")
    $StoresList = $StoresList.split(",") | Where-Object { $_ -match '^\d+$' }
    #$GroupName
    #$StoresList
    $jobCodes = ""
    if ($GroupName -like "*SL*") {
        $GroupName = $GroupName.Replace("SL", "")
        $GroupName = $GroupName + "_StoreLeadership"
        $jobCodes = '["10041","10046","10060","10061","10062","10080","10084","10085","10086","10087","10105","10140","10141","10143","10144","10145","10168","10169","10174","10176","10177","10178","10182","21083","80047","80123","80207","80215","80225","80232"]'                
    }if ($GroupName -like "*KL*") {
        $GroupName = $GroupName.Replace("KL", "")
        $GroupName = $GroupName + "_Kitchen"
        $jobCodes = '["10182","80105","80148","88063","80208","80209","80212","88065","98023"]'        
    }if ($GroupName -like "*crew*") {
        $jobCodes = '["21083","80104","80180","88063"]'
    }if ($GroupName -like "*MTO*" -or $GroupName -like "*Non*" -or $GroupName -like "*Pads*") {
        $jobCodes = '["10041","10046","10060","10061","10062","10080","10084","10085","10086","10087","10105","10140","10141","10143","10144","10145","10168","10169","10174","10176","10177","10178","10182","21083","80047","80123","80207","80215","80225","80232"]'                
    }
    else {
        #$jobCodes = $null
    }
    $DisplayName = "$GroupName"
    $Description = "$GroupName team members"
    $MailNickName = "$GroupName"
    $filterString = ""
    $StoresList | ForEach-Object {
        $filterString += '"' + "$_" + '",'
    }
    $filterString = $filterString.Substring(0, $filterString.Length - 1)
    if ($null -eq $jobCodes) {
        $filterRule = '(user.Department -in ' + '[' + $filterString + '])' + ' -and (user.extensionAttribute3 -eq "A")' 
    }
    else {
        $filterRule = '(user.Department -in ' + '[' + $filterString + '])' + ' -and (user.extensionAttribute3 -eq "A") -and (user.extensionAttribute13 -In ' + $jobCodes + ')'  
    }
    $MembershipRule = "$FilterRule"
    #Create New ADMS group
    New-DynamicGroup $DisplayName $Description $MailNickName $MembershipRule
}
