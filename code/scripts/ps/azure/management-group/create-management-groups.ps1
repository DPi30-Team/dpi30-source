# Login to Azure
Connect-AzAccount

# Global Variables
$tenantId = (Get-AzContext).Tenant.Id
$parentId = "/providers/Microsoft.Management/managementGroups/$tenantId"
$domain = Read-Host -Prompt 'Enter Azure AD Domain Name: '

# Create first level of Management Groups
New-AzManagementGroup -GroupName 'cloud-projects' -DisplayName 'Cloud Projects' -ParentId $parentId
New-AzManagementGroup -GroupName 'shared-services' -DisplayName 'Shared Services' -ParentId $parentId
New-AzManagementGroup -GroupName 'governance-services' -DisplayName 'Governance Services' -ParentId $parentId

# Create project level Management Groups (group names must be unique)
for (($i = 1), `
     ($id1 = (Get-AzManagementGroup -GroupName 'cloud-projects').Id), `
     ($id2 = (Get-AzManagementGroup -GroupName 'shared-services').Id); `
     $i -le 3; $i++) 
{ 
    New-AzManagementGroup -GroupName "cloud-project-$i" -DisplayName "Cloud Project $i" -ParentId $id1 
    New-AzManagementGroup -GroupName "shared-service-$i" -DisplayName "Shared Service $i" -ParentId $id2 
}

# Remove automatically created Owner role assignments on Management Groups
$ownerId = (Get-AzADUser -UserPrincipalName (Get-AzContext).Account.Id).Id

Remove-AzRoleAssignment -ObjectId $ownerId -Scope '/providers/Microsoft.Management/managementgroups/cloud-projects' -RoleDefinitionName 'Owner'
Remove-AzRoleAssignment -ObjectId $ownerId -Scope '/providers/Microsoft.Management/managementgroups/shared-services' -RoleDefinitionName 'Owner'
Remove-AzRoleAssignment -ObjectId $ownerId -Scope '/providers/Microsoft.Management/managementgroups/governance-services' -RoleDefinitionName 'Owner'

for ($i = 1; $i -le 3; $i++) 
{
    Remove-AzRoleAssignment -ObjectId $ownerId -Scope "/providers/Microsoft.Management/managementgroups/cloud-project-$i" -RoleDefinitionName 'Owner'
    Remove-AzRoleAssignment -ObjectId $ownerId -Scope "/providers/Microsoft.Management/managementgroups/shared-service-$i" -RoleDefinitionName 'Owner'
}

# Create cloud project team identities
New-AzADGroup -DisplayName 'Cloud Project Team' -MailNickName 'CPT'
New-AzADUser -DisplayName 'CPT User' -UserPrincipalName "cptuser@$domain" -Password (ConvertTo-SecureString 'Passw0rd!#' -AsPlainText -Force) -MailNickname 'CPTU'
Add-AzADGroupMember -MemberObjectId (Get-AzADUser -SearchString 'CPT User').Id -TargetGroupObjectId (Get-AzADGroup -SearchString 'Cloud Project Team').Id

# Create shared service team identities
New-AzADGroup -DisplayName 'Shared Service Team' -MailNickName 'SST'
New-AzADUser -DisplayName 'SST User' -UserPrincipalName "sstuser@$domain" -Password (ConvertTo-SecureString 'Passw0rd!#' -AsPlainText -Force) -MailNickname 'SSTU'
Add-AzADGroupMember -MemberObjectId (Get-AzADUser -SearchString 'SST User').Id -TargetGroupObjectId (Get-AzADGroup -SearchString 'Shared Service Team').Id

# Assign cloud project team as Contributor to Management Group
$cloudProjectTeamId = (Get-AzADGroup -SearchString 'Cloud Project Team').Id
New-AzRoleAssignment -ObjectId $cloudProjectTeamId -Scope '/providers/Microsoft.Management/managementgroups/cloud-projects' -RoleDefinitionName 'Contributor'

# Assign shared services team as Contributor to Management Group
$sharedServiceTeamId = (Get-AzADGroup -SearchString 'Shared Service Team').Id
New-AzRoleAssignment -ObjectId $sharedServiceTeamId -Scope '/providers/Microsoft.Management/managementgroups/shared-services' -RoleDefinitionName 'Contributor'

# Create subscription user identities
New-AzADUser -DisplayName 'Subscription User 1' -UserPrincipalName "subsuser1@$domain" -Password (ConvertTo-SecureString 'Passw0rd!#' -AsPlainText -Force) -MailNickname 'SUBSU1'
New-AzADUser -DisplayName 'Subscription User 2' -UserPrincipalName "subsuser2@$domain" -Password (ConvertTo-SecureString 'Passw0rd!#' -AsPlainText -Force) -MailNickname 'SUBSU2'