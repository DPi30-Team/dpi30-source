<#

.SYNOPSIS
Deploys all the policies in the root folder and child folders.

.PARAMETER rootDirectory
The location of the folder that is the root where the script will start from

.PARAMETER subscriptionId
The subscriptionid where the policies will be applied

.PARAMETER managementGroupName
The managementGroupName where the policies will be applied

.EXAMPLE
.\deploy-azure-policy-initiatives.ps1 -rootDirectory '.\policy\' -subscriptionId 323241e8-df5e-434e-b1d4-a45c3576bf80
#>
param(
    [string]$adapCMDB                     = $adapCMDB,
    [Parameter(Mandatory=$true,HelpMessage='Root Directory where Policy files are located')]
    [string] $rootDirectory,
    [string] $managementGroupName
	)


if(!$subscriptionId -and !$managementGroupName)
{
    Throw 'Unable to create policy: Subscription Id or Management Group Name were not provided. Either may be provided, but not both.'
}

if ($subscriptionId -and $managementGroupName)
{
    Throw 'Unable to create policy: Subscription Id and Management Group Name were both provided. Either may be provided, but not both.'
}

# Set working directory to path specified by rootDirectory var
Set-Location -Path $rootDirectory -PassThru

foreach($initFile in Get-ChildItem -Path $rootDirectory\* -Include *.json -Recurse)
{
	Write-Verbose -Message "Creating Policy Definition: $initFile.Name"
	New-Azdeployment -name $initFile.Name -templatefile $initFile.Fullname -location 'eastus2' -verbose
}