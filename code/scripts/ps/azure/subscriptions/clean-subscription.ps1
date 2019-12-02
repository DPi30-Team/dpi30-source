  <#
      .SYNOPSIS
      This script will remove all Resource Groups, Management Groups, Roles, Polices and Alerts in the given Azure Subscription.

      .PARAMETER subcriptionId
      The Azure Subscription Id that you want to clean up.

      .EXAMPLE
      .\clean-subscription "323241e8-df5e-434e-b1d4-a45c3576bf80"

      .INPUTS
      None. This function does not accept pipeline input.

      .OUTPUTS
	  
  #>
  [CmdletBinding()]
  param(
    [Parameter(Mandatory = $false)]
    [string]$subcriptionId = "323241e8-df5e-434e-b1d4-a45c3576bf80"
  )

  Clear-Host
  # import shared modules
Import-Module -Name $PSScriptRoot\..\..\common\subscription-management -Force

  if ([string]::IsNullOrEmpty($subcriptionId))
  {
    $subcriptionId =  Get-SubscriptionId    
  }
  # switch to selected subscription
  try
  {
    Set-AzContext -SubscriptionId $subcriptionId
    Write-Output "Subscription Id: '$subcriptionId' selected."
  }
  catch
  {
    Write-Error 'Invalid selection Subscription Id: '$subcriptionId'. Exiting...'
    exit
  }

  # remove all blueprint assignments
  $bps = Get-AzBlueprintAssignment -SubscriptionId $subcriptionId
  foreach ($bp in $bps) {
    $temp = "Deleting blueprint assignment {0}" -f $bp.Name
    Write-Host $temp
    Remove-AzBlueprintAssignment -Name $bp.Name
  }

  # todo - bust cache if locks were used
  # get a new auth token

  # loop through each rg in a sub
  $rgs = Get-AzResourceGroup
  foreach ($rg in $rgs) {
    $temp = "Deleting {0}..." -f $rg.ResourceGroupName
    Write-Host $temp
    Remove-AzResourceGroup -Name $rg.ResourceGroupName -Force # delete the current rg
    # some output on a good result
  }

  # loop through policies
  $policies = Get-AzPolicyAssignment
  foreach ($policy in $policies) {
    $temp = "Removing policy assignment: {0}" -f $policy.Name
    Write-Host $temp
    Remove-AzPolicyAssignment -ResourceId $policy.ResourceId # TODO - also print display name..
  }


    #$subscriptionScope = "/subscriptions/" + $subscription.SubscriptionId

	# Get and delete all of the policy set definitions. Skip over the built in policy definitions.
    $policySetDefinitions = Get-AzPolicySetDefinition
    foreach ($policySetDefinition in $policySetDefinitions) {
        if ($policySetDefinition.Properties.policyType -ne 'BuiltIn') {
            Write-Output "Deleting Policy Definition:" $policySetDefinition.Name
            Remove-AzPolicyDefinition `
                -Name $policySetDefinition.Name -Force -ErrorAction Continue
        }
    }

    # Get and delete all of the policy definitions. Skip over the built in policy definitions.
    $policyDefinitions = Get-AzPolicyDefinition
    foreach ($policyDefinition in $policyDefinitions) {
        if ($policyDefinition.Properties.policyType -ne 'BuiltIn') {
            Write-Output "Deleting Policy Definition:" $policyDefinition.Name
            Remove-AzPolicyDefinition `
                -Name $policyDefinition.Name -Force -ErrorAction Continue
        }
    }


  # get-azroleassignment returns assignments at current OR parent scope`
  # will need to do a check on the scope property
  # todo - not entirely sure how well this is working...
  $rbacs = Get-AzRoleAssignment 
  foreach ($rbac in $rbacs) {
    if ($rbac.Scope -eq "/subscriptions/$subscriptionId") { # extra logic to make sure we are only removing role assignments at the target sub
        Write-Output "Found a role assignment to delete"
        Remove-AzRoleAssignment -InputObject $rbac
    } else {
        $temp = "NOT deleting role with scope {0}" -f $rbac.Scope
        Write-Host $temp
    }
  }
