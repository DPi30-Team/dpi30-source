# SQL Server 

Deploys a SQL Server 

## Paramaters

**sqlServerName**: (required) string

Name of SQL Server.
Will be created in the same resource group as the script is run and in the default location for resource group.
The fully qualified domain name of the SQL server is available as an output of the template - sqlServerFqdn

**sqlServerAdminUserName**: (optional) string

SQL SA administrator username.
Only used if the database does not exist and needs creating.
Only used when the server is created.
Does not change settings if the server already exists (will not change the admin username on an existing server).
The username is available as an output of the template - saAdministratorLogin

**sqlServerAdminPassword**: (required) securestring

SQL SA administrator password.
Only used when the server is created.
Does not change settings if the server already exists (will not change the admin password on an existing server).

**storageAccountName**: (required) string

Name of a storage account to store logs to.

**sqlServerActiveDirectoryAdminLogin**: (required) string

Name of AAD user or group to grant administrator rights to.

**sqlServerActiveDirectoryAdminObjectId**: (required) string

Object ID of AAD user or group above.

**threatDetectionEmailAddress**: (optional) array

Array of email addresses to send the threat detected emails to.
If not provided will not email anyone.


