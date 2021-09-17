try { 
    $var = Get-AzureADTenantDetail 
} 
catch [Microsoft.Open.Azure.AD.CommonLibrary.AadNeedAuthenticationException] { 
    Write-Host "You're not connected to AzureAD"; 
    Write-Host "Make sure you have AzureAD mudule available on this system then use Connect-AzureAD to establish connection"; 
    $Credential = Get-Credential
    Connect-AzureAD -Credential $Credential
}