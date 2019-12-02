<#

    .SYNOPSIS
    Deploys all action groups

    .DESCRIPTION
    This script will loop through the root folder and child folders and create the actiongroups defined

    .PARAMETER rootDirectory
    The location of the folder that is the root where the script will start from

    .PARAMETER subscriptionId
    The subscriptionid where the actiongroups will be applied

    .EXAMPLE
    .\deploy-ActionGroupDefs.ps1 -rootDirectory '.\actiongroups\' -subscriptionId 323241e8-df5e-434e-b1d4-a45c3576bf80 -resourceGroupName rg-alerts
#>
param(
    [Parameter(Mandatory=$true,HelpMessage='Root Directory where Policy files are located')]
    [string] $rootDirectory,
    [Parameter(Mandatory = $false)]
    [string] $resourceGroupName = $mgmtResourceGroup
	)


# Set working directory to path specified by rootDirectory var
Set-Location -Path $rootDirectory -PassThru

if(!$subscriptionId)
{
    Throw 'Unable to create actiongroup: Subscription Id not provided.'
}

foreach($parentDir in Get-ChildItem -Directory)
{
    foreach($childDir in Get-ChildItem -Path $parentDir -Directory)
    {
        $templateFile = ('{0}\{1}\azuredeploy.json' -f $parentDir, $childDir)
        $paramFile = ('{0}\{1}\azuredeploy.parameters.json' -f $parentDir, $childDir)

        $agDeploy = New-AzResourceGroupDeployment -Name $childDir -ResourceGroupName $resourceGroupName -TemplateFile $templateFile -TemplateParameterFile $paramFile

        Write-Host 'deploying actiongroup: ' $childDir
        }
    }