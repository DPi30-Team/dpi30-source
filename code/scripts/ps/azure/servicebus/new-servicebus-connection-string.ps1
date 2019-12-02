<#
    .SYNOPSIS
    Get a Connection String for a Service Bus namespace.

    .DESCRIPTION
    Get a Connection String for a Service Bus namespace. If one does not exist with the given name, it will be created.

    .PARAMETER NamespaceName
    The name of the Service Bus namespace.

    .PARAMETER AuthorizationRuleName
    The name of the authorization rule to be created.

    .PARAMETER Rights
    A list of authorization rule rights. This can be one or all of the following:
    Listen
    Send
    Manage

    .PARAMETER ConnectionStringType
    The Connection String to return. This can be either be Primary or Secondary.

    .EXAMPLE
    .\New-ServiceBusConnectionString.ps1 -NamespaceName test-namespace -AuthorizationRuleName auth1 -Rights Listen, Send, Manage -ConnectionStringType Secondary

    Return the Secondary Connection String for the specified authorization rule, if the authorization rule does not exist it will be created.
#>

[CmdletBinding()]
Param (
    [Parameter(Mandatory = $true)]
    [String]$NamespaceName,
    [Parameter(Mandatory = $true)]
    [String]$AuthorizationRuleName,
    [Parameter(Mandatory = $true)]
    [ValidateSet("Listen", "Send", "Manage")]
    [String[]]$Rights,
    [Parameter(Mandatory = $false)]
    [ValidateSet("Primary", "Secondary")]
    [String[]]$ConnectionStringType = "Primary"
)

try {

    $ServiceBusResource = Get-AzResource -Name $NamespaceName
    if (!$ServiceBusResource) {
        throw "Could not find Service Bus namespace $NamespaceName"
    }

    $AuthorizationRule = Get-AzServiceBusAuthorizationRule -ResourceGroupName $ServiceBusResource.ResourceGroupName -Namespace $NameSpaceName -Name $AuthorizationRuleName -ErrorAction SilentlyContinue
    if (!$AuthorizationRule) {
        $AuthorizationRuleParameters = @{
            ResourceGroupName = $ServiceBusResource.ResourceGroupName
            Namespace         = $NamespaceName
            Name              = $AuthorizationRuleName
            Rights            = $Rights
        }
        $null = New-AzServiceBusAuthorizationRule @AuthorizationRuleParameters
    }

    $ServiceBusKey = Get-AzServiceBusKey -ResourceGroupName $ServiceBusResource.ResourceGroupName -Namespace $NamespaceName -Name $AuthorizationRuleName
    switch ($ConnectionStringType) {
        'Primary' {
            $ConnectionString = $ServiceBusKey.PrimaryConnectionString
            break
        }
        'Secondary' {
            $ConnectionString = $ServiceBusKey.SecondaryConnectionString
            break
        }
    }

    Write-Output ("##vso[task.setvariable variable=ServiceBusConnectionString; issecret=true]$($ConnectionString)")

}

catch {
    throw $_
}
