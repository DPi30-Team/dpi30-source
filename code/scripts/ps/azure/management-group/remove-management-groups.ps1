# Login to Azure
Connect-AzAccount

# Remove project level Management Groups
for ($i = 1; $i -le 3; $i++) 
{ 
    Remove-AzManagementGroup -GroupName "cloud-project-$i" 
    Remove-AzManagementGroup -GroupName "shared-service-$i" 
}

# Remove first level Management Groups
Remove-AzManagementGroup -GroupName 'cloud-projects'
Remove-AzManagementGroup -GroupName 'shared-services'
Remove-AzManagementGroup -GroupName 'governance-services'

# Remove cloud project team identities
Get-AzADUser -SearchString 'CPT User' | Remove-AzADUser -Force
Remove-AzADGroup -ObjectId (Get-AzADGroup -SearchString 'Cloud Project Team').Id -PassThru -Force

# Remove shared service team identities
Get-AzADUser -SearchString 'SST User' | Remove-AzADUser -Force
Remove-AzADGroup -ObjectId (Get-AzADGroup -SearchString 'Shared Service Team').Id -PassThru -Force

# Remove subscription user identities
Get-AzADUser -SearchString 'Subscription User 1' | Remove-AzADUser -Force
Get-AzADUser -SearchString 'Subscription User 2' | Remove-AzADUser -Force