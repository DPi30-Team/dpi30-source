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
.\deploy-azure-policy-definitions.ps1 -rootDirectory '.\policy\' -subscriptionId 323241e8-df5e-434e-b1d4-a45c3576bf80
#>
param(
	[string]$adapCMDB                     = $adapCMDB,
    [Parameter(Mandatory=$true,HelpMessage='Root Directory where Policy files are located')]
    [string] $rootDirectory,
    [Parameter(Mandatory = $false)]
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

foreach($parentDir in Get-ChildItem -Directory)
{
    foreach($childDir in Get-ChildItem -Path $parentDir -Directory)
    {
        $configFile = ('{0}\{1}\policy.config.json' -f $parentDir, $childDir)
        $rulesFile = ('{0}\{1}\policy.rules.json' -f $parentDir, $childDir)
        [string]$paramFile = ('{0}\{1}\policy.parameters.json' -f $parentDir, $childDir)

        $policyName  = (Get-Content -Path $configFile | ConvertFrom-Json).config.policyName.value
        $policyDisplayName = (Get-Content -Path $configFile | ConvertFrom-Json).config.policyDisplayName.value
        $policyDescription = (Get-Content -Path $configFile | ConvertFrom-Json).config.policyDescription.value
        $policyCategory = (Get-Content -Path $configFile | ConvertFrom-Json).config.policyCategory.value

        $policyExists = Get-AzPolicyDefinition -Name $policyName -ErrorAction SilentlyContinue
        if (!$policyExists)
        {
          $cmdletParameters = @{Name=$policyName
            Policy=$rulesFile
            Parameter=$paramFile
          Mode='Indexed'}

          if ($policyCategory)
          {
              $cmdletParameters += @{Metadata=$policyCategory}
          }

          if ($policyDisplayName)
          {
              $cmdletParameters += @{DisplayName=$policyDisplayName}
          }

          if ($policyDescription)
          {
              $cmdletParameters += @{Description=$policyDescription}
          }

          if ($subscriptionId)
          {
              $cmdletParameters += @{SubscriptionId=$subscriptionId}
          }

          if ($managementGroupName)
          {
              $cmdletParameters += @{ManagementGroupName=$managementGroupName}
          }
          Write-Host 'deplying policy: ' $policyName
          &New-AzPolicyDefinition @cmdletParameters
        }
    }
}