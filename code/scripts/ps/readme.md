

### Deployment

```ps
 .\dpi30-deploy-adap-platform.ps1 `
 -adGroups
 -adServicePrincipals
 -adUsers
 -azPolicies
 -azInitiatives
 -azRoles
 -azRoleAssignments
 -azAlerts
 -azBlueprints
 -azParameterFiles
```

### What this script does
  - Create Azure Active Directory Security Groups
  - Create Azure Active Directory Security Principals
  - Create Azure Active Directory Users
  - Deploy Azure Key Vault
  - Create Azure Policies/Initiatives
  - Create Azure Roles/Role Assignments
  - Create Azure Action Groups/Alerts  
  - Create Azure ARM Template Parameter Files from Excel Spreadsheet