<#
    .SYNOPSIS
    Return either the primary or secondary connection string for a Storage Account and write to a Azure Pipelines variable.

    .DESCRIPTION
    Return either the primary or secondary connection string for a Storage Account and write to a Azure Pipelines variable.

    .PARAMETER ResourceGroup
    The name of the Resource Group that contains the Storage Account.

    .PARAMETER StorageAccount
    The name of the Storage Account.

    .PARAMETER UseSecondaryKey
    Boolean Switch to return the secondary connection string.

    .PARAMETER OutputVariable
    The name of the variable to be used by Azure Pipelines.

    .EXAMPLE
    .\Get-StorageAccountConnectionString.ps1 -ResourceGroup rgname -StorageAccount saname

    Returns the Primary Storage Account connection string.

    .EXAMPLE
    .\Get-StorageAccountConnectionString.ps1 -ResourceGroup rgname -StorageAccount saname -UseSecondaryKey

    Returns the Secondary Storage Account connection string.

    .EXAMPLE
    .\Get-StorageAccountConnectionString.ps1 -ResourceGroup rgname -StorageAccount saname -OutputVariable "CustomOutputVariable"

    Returns the Primary Storage Account connection string and specifies a custom output variable to be used in VSTS.
#>

[CmdletBinding()]
Param(
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [String]$ResourceGroup,
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [String]$StorageAccount,
    [Parameter(Mandatory = $false)]
    [switch]$UseSecondaryKey,
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [String]$OutputVariable = "StorageConnectionString"
)

try {
    # --- Check if the Resource Group exists in the subscription.
    $ResourceGroupExists = Get-AzResourceGroup $ResourceGroup
    if (!$ResourceGroupExists) {
        throw "Resource Group $ResourceGroup does not exist."
    }

    # --- Check if Storage Account exists in the subscription.
    $StorageAccountExists = Get-AzStorageAccount -ResourceGroupName $ResourceGroup -Name $StorageAccount -ErrorAction SilentlyContinue
    if (!$StorageAccountExists) {
        throw "Storage Account $StorageAccount does not exist."
    }

    # --- Return the respective Storage Account connection string.
    if ($UseSecondaryKey.IsPresent) {
        $Key = (Get-AzStorageAccountKey -ResourceGroupName $ResourceGroup -Name $StorageAccount)[1].Value
        $ConnectionString = "DefaultEndpointsProtocol=https;AccountName=$($StorageAccount);AccountKey=$($Key);EndpointSuffix=core.windows.net"
    }
    else {
        $Key = (Get-AzStorageAccountKey -ResourceGroupName $ResourceGroup -Name $StorageAccount)[0].Value
        $ConnectionString = "DefaultEndpointsProtocol=https;AccountName=$($StorageAccount);AccountKey=$($Key);EndpointSuffix=core.windows.net"
    }

    # --- Set the VSTS output variable using the returned connection string.
    Write-Output ("##vso[task.setvariable variable=$($OutputVariable);issecret=true]$($ConnectionString)")
}

catch {
    throw "$_"
}
