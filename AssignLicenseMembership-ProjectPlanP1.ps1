$userUPN=""
$planName="PROJECT_P1"
$License = New-Object -TypeName Microsoft.Open.AzureAD.Model.AssignedLicense
$License.SkuId = (Get-AzureADSubscribedSku | Where-Object -Property SkuPartNumber -Value $planName -EQ).SkuID
$LicensesToAssign = New-Object -TypeName Microsoft.Open.AzureAD.Model.AssignedLicenses
$LicensesToAssign.AddLicenses = $License
Foreach($user in $userUPN){
    if(# p3 license assigned){
       }
    else{
      Set-AzureADUserLicense -ObjectId $user -AssignedLicenses $LicensesToAssign
    } 
  }