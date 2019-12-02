

param(
  [Parameter(Mandatory = $true)]
  [string]$GroupName

)

try {
  $groupId = Get-AzureADGroup -All $true | Where-Object { $_.Displayname -eq $GroupName } | Select-Object ObjectId
  Write-Output "##vso[task.setvariable variable=$OutputName]$groupId" 
}
catch {
  Throw "Group not found"
}
