<#
.SYNOPSIS
    Returns default configuration values that will be used by the Reference Architecture Data Platform 
#>
function Get-Configuration
{
  $configuration = @{`
    primaryLocation = "eastus"
    primaryLocationName = "East US"
	primaryLocationTag = "eus"
	mgmtResourceGroup = "mgmt-dev-eus-rg"
	vnetResourceGroup = "vnet-dev-eus-rg"
	secuResourceGroup = "secu-dev-eus-rg"
	bastResourceGroup = "bast-dev-eus-rg"
    azureAdmin = "deployAdmin@azuresecurity.net"
    azureADAdmin = "deployAdmin@azuresecurity.net"
	subscriptionId = "323241e8-df5e-434e-b1d4-a45c3576bf80"
	aadDirectoryName = "azurearchitecture"
	tenentId = "3ae449e7-25e5-4e5d-b705-7a39e1ad16f0"
	subscriptionname = "AzureArch"
    azureAdminPwd = 'Z1!xcvbnmnbvcxz'# (Get-AzKeyVaultSecret -VaultName 'adap-deploy-rg-kv' -Name 'azureADAdminPwd' -).SecretValueText
    azureADAdminPwd = 'Z1!xcvbnmnbvcxz'# (Get-AzKeyVaultSecret -VaultName 'adap-deploy-rg-kv' -Name 'azureAdminPwd' -).SecretValueText
    deployResourceGroupName = "adap-smk-eus-rg"
    azureEnvironment = "AzureCloud"
    }
    return $configuration
}