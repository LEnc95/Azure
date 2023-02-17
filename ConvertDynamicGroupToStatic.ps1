$mydynamicGroup = "DynamicMembership"

function ToConvertDynamicGroupToStatic
{
    Param([string]$groupId)

    
    [System.Collections.ArrayList]$mygroupTypes = (Get-AzureAdMsGroup -Id $mygroupId).GroupTypes

    if($mygroupTypes -eq $null -or !$mygroupTypes.Contains($mydynamicGroup))
    {
        throw "This group is already a static group. No changes required.";
    }


    $mygroupTypes.Remove($mydynamicGroup)

    Set-AzureAdMsGroup -Id $mygroupId -GroupTypes $mygroupTypes.ToArray() -MembershipRuleProcessingState "Paused"
}

ToConvertDynamicGroupToStatic "23359f6d-850e-47e3-96b3-6ccae2ecb7bd"