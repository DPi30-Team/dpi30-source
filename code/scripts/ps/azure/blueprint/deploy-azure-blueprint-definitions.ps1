<#

    .SYNOPSIS
    Deploys all the blueprints in the root folder and child folders.

    .PARAMETER rootDirectory
    The location of the folder that is the root where the script will start from

    .PARAMETER subscriptionId
    The subscriptionid where the blueprints will be applied

    .PARAMETER managementGroupName
    The managementGroupName where the blueprints will be applied

    .EXAMPLE
    .\deploy-azure-blueprint-definitions.ps1 -rootDirectory '.\blueprint\' -subscriptionId 323241e8-df5e-434e-b1d4-a45c3576bf80
#>
param(
    [string]$adapCMDB                     = $adapCMDB,
    [Parameter(Mandatory=$true,HelpMessage='Root Directory where Blueprint files are located')]
    [string] $rootDirectory,
    [string] $managementGroupName
)


Import-Module Azure.Storage
Import-Module Az.Blueprint

if(!$subscriptionId -and !$managementGroupName)
{
    Throw 'Unable to create blueprint: Subscription Id or Management Group Name were not provided. Either may be provided, but not both.'
}

if ($subscriptionId -and $managementGroupName)
{
    Throw 'Unable to create blueprint: Subscription Id and Management Group Name were both provided. Either may be provided, but not both.'
}

# Set working directory to path specified by rootDirectory var
Set-Location -Path $rootDirectory -PassThru

$BPFolders = Get-ChildItem $rootDirectory
foreach($BPFolder in $BPFolders) {
    $BPName = $BPFolder.Name
    Import-AzBlueprintWithArtifact `
        -Name $BPName `
        -InputPath $BPFolder.FullName `
        -SubscriptionId $subscriptionId `
        -Force `
        -Verbose

  # success
  if ($?) {
    Write-Host "Imported successfully"

    $date = Get-Date -UFormat %Y%m%d%H%M%S
    $genVersion = "$date" # todo - use the version from DevOps

    $importedBp = Get-AzBlueprint -Name $BPName
    Publish-AzBlueprint -Blueprint $importedBp -Version $genVersion

    # TODO - Clean up old test version(s)
  } else {
    throw "Failed to import successfully"
    exit 1
  }
}
<#
  $importedBp = Get-AzBlueprint -Name $BPName -LatestPublished
  # Urgent TODO - this should be idemopotent...
  # todo - should auto-insert blueprintId into parameters file
  $bpfile = ('{0}\{1}' -f  $BPFolder.FullName, "Blueprint.json")
  $bpfile
  New-AzBlueprintAssignment -Name "$BPName" -Blueprint $importedBp -AssignmentFile $bpfile -SubscriptionId $subscriptionId

  # Wait for assignment to complete
  $timeout = new-timespan -Seconds 500
  $sw = [diagnostics.stopwatch]::StartNew()

  while (($sw.elapsed -lt $timeout) -and ($AssignemntStatus.ProvisioningState -ne "Succeeded") -and ($AssignemntStatus.ProvisioningState -ne "Failed")) {
    $AssignemntStatus = Get-AzBlueprintAssignment -Name "$BPName" -SubscriptionId $subscriptionId
    if ($AssignemntStatus.ProvisioningState -eq "failed") {
      Throw "Assignment Failed. See Azure Portal for details."
      break
    }
  }

  if ($AssignemntStatus.ProvisioningState -ne "Succeeded") {
    Write-Warning "Assignment has timed out, activity is exiting."
  }

  # publish 'stable' version
  $date = Get-Date -UFormat %Y%m%d.%H%M%S
  $genVersion = "$date.STABLE" # todo - use the version from DevOps
  #Publish-AzBlueprint -Blueprint $importedBp -Version $genVersion

  #>