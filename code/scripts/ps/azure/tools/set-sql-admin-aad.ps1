
param(
  [Parameter(Mandatory = $true)]
  [string]$GroupName,
   [Parameter(Mandatory=$true)][string]$resourceGroupName,
    [Parameter(Mandatory=$true)][string]$serverName

)

try{
  $groupId = Get-AzureADGroup -All $true | Where-Object {$_.Displayname -eq $GroupName} | Select-Object -ExpandProperty ObjectId
  Set-AzSqlServerActiveDirectoryAdministrator -ResourceGroupName $resourceGroupName -ServerName $serverName -DisplayName $GroupName -ObjectId $groupId
}
catch{
  Throw "Azure AD Group for SQL not Set"
}
