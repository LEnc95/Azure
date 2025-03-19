Get-AzureADUser -ObjectId luke.encrapera@gianteagle.com | Select-Object -ExpandProperty ExtensionProperty | Format-List

# Define value you are looking for
$attributeKey = "extension_2d6e2cfd86d742e5baf5ae04a70c842d_extensionAttribute13"
$attributeValue = "31244"

Get-AzureADUser -All $true | Where-Object {
    $_.ExtensionProperty[$attributeKey] -eq $attributeValue
} | Select-Object DisplayName, UserPrincipalName, @{Name="AttributeValue";Expression={$_.ExtensionProperty[$attributeKey]}}
