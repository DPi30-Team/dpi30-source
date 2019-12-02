<# 
.SYNOPSIS
Create custom roles in Azure

.DESCRIPTION
This script will loop through all the files in the root directory and create roles

.PARAMETER rootDirectory
The root directory that contains the Role definitions

.PARAMETER subscriptionId
The subscription to create the roles in

.EXAMPLE 
.\scripts\Create-RoleDefinition.ps1 -rootDirectory '.\roles\' 

.NOTES
Depends on and submgmt.psm1, config.psm1
AUTHOR: [Author] 
LASTEDIT: April 29, 2019
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory=$true,HelpMessage='Root Directory where Role files are located')]
    [string] $rootDirectory)



if(!$subscriptionId)
{
    Throw 'Unable to create Role: Subscription Id not provided.'
}

if(!$rootDirectory)
{
    Throw 'Unable to create Role: rootDirectory not provided.'
}

Set-Location -Path  $rootDirectory -PassThru

foreach($parentDir in Get-ChildItem -Directory)
{

      foreach($roleFile in Get-ChildItem -Path $parentDir\* -Include *.json -Recurse)
      {
		Write-Verbose -Message "Creating Azure Role  Role: $($AzureRole) Scope: $($Scope) SubscriptionId: $($subscriptionId) Resource Group: $($ResourceGroup)"
        $role = $roleFile.FullName
        $roledefinition = Get-Content -Path $roleFile.FullName
        $roledefinitionNew = $roledefinition -Replace "subscriptionId", "$subscriptionId"
        Set-Content -Path $role -Value $roledefinitionNew
		New-AzRoleDefinition -InputFile $role
      }
  }