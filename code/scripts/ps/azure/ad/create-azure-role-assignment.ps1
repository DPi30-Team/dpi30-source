<# 
.SYNOPSIS 
Set Azure Role Assignemnts

.DESCRIPTION 
This script will Assign the Azure Active Directory Security Group to a cosrrosponfing Azure Role

.PARAM AADname
Admin name of the AAD Domain
    
.PARAM AADPassword 
Administrator's password
    
.PARAM RoleAssignCSV
CSV file containing role/group definition

.EXAMPLE 
.\Create-RoleAssignments.ps1 -RoleAssignCSV RoleAssign.csv

.NOTES
Depends on and submgmt.psm1, config.psm1
AUTHOR: [Author] 
LASTEDIT: April 29, 2019
#>
[CmdletBinding()]
Param ( 
	[Parameter(Mandatory=$true,HelpMessage='File name that has the Role to Azure AD Assignments')]
	[string]$RoleAssignCSV  = 'RoleAssign.csv'        
)   


# ====================
# Begin Script
# ====================
$VerbosePreference = 'continue' # "silentlycontinue"

## Process CSV file
if ( -not (Test-path -Path $PSScriptRoot\..\config\$RoleAssignCSV))
{
  Write-Verbose -Message "No file specified or file $PSScriptRoot\..\config\$RoleAssignCSV does not exist."
  return
}

#Get list of Roles from File   
$ListofRoles = Import-Csv -Path $PSScriptRoot\..\config\$RoleAssignCSV    

foreach ($U in $ListofRoles)
{
  if ($U.ADGroupName)
  {
    $ADGroupName     = $U.ADGroupName
    $AzureRole       = $U.AzureRole
    $ResourceGroup   = $U.ResourceGroup
    $Scope           = $U.Scope
  }

  $adGroup = Get-AzureADGroup -SearchString $ADGroupName
  if ($adGroup)
  {
    $ObjectId = $adGroup.ObjectId 
    Write-Verbose -Message "Setting Azure AD Role Assignmentt - ADGroup: $($ADGroupName) Role: $($AzureRole) Scope: $($Scope) SubscriptionId: $($subscriptionId) Resource Group: $($ResourceGroup)"
    Write-Verbose -Message "New-AzRoleAssignment -ObjectId $ObjectId -RoleDefinitionName $AzureRole"
    switch ($Scope) {
      'subscription' {
        $ScopePath = "/subscriptions/$subscriptionId"
        #New-AzRoleAssignment -ObjectId $ObjectId -RoleDefinitionName $AzureRole -Scope $ScopePath
        break
      }
      'resourceGroups' {
        $ScopePath = $ResourceGroup
        #New-AzRoleAssignment -ObjectId $ObjectId -RoleDefinitionName $AzureRole -ResourceGroupName $ScopePath
        break
      }
      default { throw New-Object -TypeName ArgumentException -ArgumentList ('data') }
    }
  }
}
