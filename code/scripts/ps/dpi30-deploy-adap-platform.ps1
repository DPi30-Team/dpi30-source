 
  <#
      .SYNOPSIS
        This script deploys the ADAP platform based on the values in the adap-cmdb.xlsx spreadsheet.

      .PARAMETER -adServicePrincipals -adUsers -azPolicies -azInitiatives -azRoles -azRoleAssignments -azAlerts -azBlueprints -azParameterFiles
        Switch to deploy the resources

      .PARAMETER debugAction (default off)
        Switch to enable debugging output

      .PARAMETER actionVar (default SilentlyContinue)
        Switch to enable debugging output

      Stop: Displays the error message and stops executing.
      Inquire: Displays the error message and asks you whether you want to continue.
      Continue: (Default) Displays the error message and continues executing.
      Suspend: Automatically suspends a work-flow job to allow for further investigation. After investigation, the work-flow can be resumed.
      SilentlyContinue: No effect. The error message isn't displayed and execution continues without interruption.

      .EXAMPLE
        .\dpi30-deploy-adap-platform -azBlueprints -azParameterFiles
        .\dpi30-deploy-adap-platform -adGroups -adServicePrincipals -adUsers -azPolicies -azInitiatives -azRoles -azRoleAssignments -azAlerts -azBlueprints -azParameterFiles


  #>
  [CmdletBinding()]
  param(
    [Parameter(ValueFromPipeline = $true,
      ValueFromPipelineByPropertyName = $true)]
      [Switch]$adGroups = $false,
    [Parameter(ValueFromPipeline = $true,
      ValueFromPipelineByPropertyName = $true)]
      [Switch]$adServicePrincipals = $false,
    [Parameter(ValueFromPipeline = $true,
      ValueFromPipelineByPropertyName = $true)]
      [Switch]$adUsers = $false,
    [Parameter(ValueFromPipeline = $true,
      ValueFromPipelineByPropertyName = $true)]
      [Switch]$azPolicies = $false,
    [Parameter(ValueFromPipeline = $true,
      ValueFromPipelineByPropertyName = $true)]
      [Switch]$azInitiatives = $false,
    [Parameter(ValueFromPipeline = $true,
      ValueFromPipelineByPropertyName = $true)]
      [Switch]$azRoles = $false,
    [Parameter(ValueFromPipeline = $true,
      ValueFromPipelineByPropertyName = $true)]
      [Switch]$azRoleAssignments = $false,
    [Parameter(ValueFromPipeline = $true,
      ValueFromPipelineByPropertyName = $true)]
      [Switch]$azAlerts = $false,
    [Parameter(ValueFromPipeline = $true,
      ValueFromPipelineByPropertyName = $true)]
      [Switch]$azBlueprints = $false,
    [Parameter(ValueFromPipeline = $true,
      ValueFromPipelineByPropertyName = $true)]
      [Switch]$azParameterFiles = $true,
    [Parameter(ValueFromPipeline = $true,
      ValueFromPipelineByPropertyName = $true)]
      [Switch]$debugAction = $false,
    [Parameter(ValueFromPipeline = $true,
      ValueFromPipelineByPropertyName = $true)]
      [validateset('Stop','Inquire','Continue','Suspend','SilentlyContinue')]
      [string]$actionVerboseVariable = 'Continue',
    [Parameter(ValueFromPipeline = $true,
      ValueFromPipelineByPropertyName = $true)]
      [validateset('Stop','Inquire','Continue','Suspend','SilentlyContinue')]
      [string]$actionErrorVariable = 'SilentlyContinue',
    [Parameter(ValueFromPipeline = $true,
      ValueFromPipelineByPropertyName = $true)]
      [validateset('Stop','Inquire','Continue','Suspend','SilentlyContinue')]
      [string]$actionDebugVariable = 'SilentlyContinue'

  )

  $DefaultVariables = $(Get-Variable).Name

  #$null = "$actionErrorVariable"
  $actionVerbosePreference = "$actionVerboseVariable"
  $actionDebugPreference = "$actionDebugVariable"
  $psscriptsRoot = $PSScriptRoot

  Set-PSDebug -Off
  if($debugAction){
    Set-PSDebug -Trace 1
  }

  #Folder Locations
  $psCommonDirectory = "$psscriptsRoot\common"
  $psConfigDirectory = "$psscriptsRoot\config"
  $psAzureDirectory = "$psscriptsRoot\azure"
  $armTemplatesDirectory = "$psscriptsRoot\..\..\arm\templates"
  $armAlertDirectory = "$psscriptsRoot\..\..\arm\alert"
  $armBluePrintDirectory = "$psscriptsRoot\..\..\arm\blueprint"
  $armPolicyDirectory = "$psscriptsRoot\..\..\arm\policy"
  $armRBACDirectory = "$psscriptsRoot\..\..\arm\RBAC"

  $adapCMDBfile = ''
  $adapCMDBfile = 'adap-cmdb.xlsm'
  $adapCMDB = "$psConfigDirectory\$adapCMDBfile"

  if ( -not (Test-path ('{0}\azure-common.psm1' -f $psCommonDirectory)))
  {
    Write-Verbose -Message ('Shared PS modules can not be found, Check path {0}\azure-common.psm1.' -f $psCommonDirectory)  -Verbose
    Exit
  }
  ## Check path to CMDB
  if ( -not (Test-path -Path $adapCMDB))
  {
    Write-Verbose -Message ('No file specified or file {0}\{1} does not exist.' -f $psConfigDirectory, $adapCMDBfile)  -Verbose
    Exit
  }

  try{
    $azureCommon = ('{0}\{1}' -f  $psCommonDirectory, 'azure-common')
    Import-Module -Name $azureCommon -Force 

    #Set Config Values
    $configurationFile = ('{0}\{1}' -f  $psConfigDirectory, 'adap-configuration')
    Import-Module -Name $configurationFile -Force 
    $config = Get-Configuration
  }
  catch {
    Write-Verbose -Message ("Error importing reguired PS modules: $azureCommon, $configurationFile") -Verbose
    $PSCmdlet.ThrowTerminatingError($_)
    Exit
  }

  # Load PS Modules
  Get-PSModules
  
  #Set Common variables from config file.
  Write-Verbose -Message ("Getting common variables from config file: $configurationFile") -Verbose
  try {
    $primaryLocation = $config.primaryLocation
    $primaryLocationName = $config.primaryLocationName
    $primaryLocationTag = $config.primaryLocationTag
    $mgmtResourceGroup = $config.mgmtResourceGroup
    $vnetResourceGroup = $config.vnetResourceGroup
    $secuResourceGroup = $config.secuResourceGroup
    $bastResourceGroup = $config.bastResourceGroup
    $azureAdmin = $config.azureAdmin
    $azureADAdmin = $config.azureADAdmin
    $subscriptionId = $config.subscriptionId
    $aadDirectoryName = $config.aadDirectoryName
    $tenentId = $config.tenentId
    $subscriptionName = $config.subscriptionName
    $azureAdminPwd = $config.azureAdminPwd
    $azureADAdminPwd = $config.azureADAdminPwd
    $deployResourceGroupName = $config.deployResourceGroupName
    $azureEnvironment = $config.azureEnvironment
  }
  catch {
    Write-Verbose -Message 'Configuration variable must be set in {0}, Check values and path.' -Message -f  $configurationFile, $adapCMDB
    Write-Verbose -Message 'Press any key to exit...'
    Exit
  }

  #Logon to Azure & Azure AD with values from config file
  Write-Verbose -Message ("Logon to Azure with values from config file: $configurationFile") -Verbose
  try{
      $username = $azureAdmin
      $password = $azureAdminPwd
      $subname = $subscriptionName

      $secpasswd = ConvertTo-SecureString $password -AsPlainText -Force
      $cred = New-Object System.Management.Automation.PSCredential ($userName, $secpasswd)
      Connect-AzAccount  -Credential $cred
      $sub = Get-AzSubscription -SubscriptionName $subname
      Connect-AzAccount -Credential $cred -Tenant $sub.TenantId -SubscriptionId $sub.SubscriptionId
      Set-AzContext -SubscriptionName $subname

      $currentAzureContext = Get-AzContext
      if($adGroups -or $adServicePrincipals -or $adUsers){
        Write-Verbose -Message ("Logon to Azure AD with values from config file: $configurationFile") -Verbose
        $tenantId = $currentAzureContext.Tenant.Id
        $accountId = $currentAzureContext.Account.Id
        Connect-AzureAD -TenantId $tenantId -AccountId $accountId
      }

      $subscriptionId = Get-SubscriptionId
      Set-AzContext -SubscriptionId $subscriptionId
      $subscriptionName = (Get-AzContext).Subscription.SubscriptionName
  }
  catch{
    Write-Verbose -Message 'Configuration variable must be set in {0}, Check values and path.' -f  $configurationFile, $adapCMDB
    Write-Verbose -Message 'Press any key to exit...'
    Exit
  
  }

  # Start Deployment of Azure Assets
   Write-Verbose -Message ('Starting deployment of Azure Assets') -Verbose

  # Deploy Azure Active Directory Groups
  if($adGroups){
    Write-Verbose -Message ('Starting deployment of Azure Active Directory Groups') -Verbose
    Set-Location -Path $psAzureDirectory
    .\ad\create-azure-ad-groups.ps1 -adapCMDB $adapCMDB -action 'create' # purge or create
  }

  # Deploy Azure Active Directory Service Principals
  if($adServicePrincipals){
    Write-Verbose -Message ('Starting deployment of Azure Active Directory Service Principals') -Verbose
    Set-Location -Path $psAzureDirectory
    .\ad\create-azure-service-principal.ps1 -adapCMDB $adapCMDB -action 'create' # purge or create
  }

  # Deploy Azure Active Directory Users
  if($adUsers){
    Write-Verbose -Message ('Starting deployment of Azure Active Directory Users') -Verbose
    Set-Location -Path $psAzureDirectory
    .\ad\create-azure-ad-users.ps1 -adapCMDB $adapCMDB -action 'create' # purge or create
  }

  # Deploy Azure Policies
  if($azPolicies){
    Write-Verbose -Message ('Starting deployment of Azure Policies') -Verbose
    Set-Location -Path $psAzureDirectory
    .\policy\deploy-azure-policy-definitions.ps1 -rootDirectory "$armPolicyDirectory\policies\"
  }

  # Deploy Azure Initiatives
  if($azInitiatives){
    Write-Verbose -Message ('Starting deployment of Azure Initiatives') -Verbose
    Set-Location -Path $psAzureDirectory
    .\policy\deploy-azure-policy-initiatives.ps1 -rootDirectory "$armPolicyDirectory\initiatives\"
  }
  
  # Deploy Azure Blueprint
  if($azBlueprints){
    Write-Verbose -Message ('Starting deployment of Azure Alerts') -Verbose
    Set-Location -Path $psAzureDirectory
    .\blueprint\deploy-azure-blueprint-definitions.ps1 -rootDirectory "$armBluePrintDirectory\"
  }
  
 
  # Deploy Azure Alerts Action Groups
  if($azAlerts){
    Write-Verbose -Message ('Starting deployment of Azure Alerts Action Groups') -Verbose
    Set-Location -Path $psAzureDirectory
    .\alert\deploy-azure-action-group-defs.ps1 -rootDirectory "$armAlertDirectory\actiongroup\"
    .\alert\deploy-azure-alert-defs.ps1 -rootDirectory "$armAlertDirectory\alerts\"
  }

  # Deploy Azure ARM Parameter Files
  if($azParameterFiles){
    Set-Location -Path $psAzureDirectory
    Write-Verbose -Message ('Starting deployment of Azure ARM Parameter Files') -Verbose
    .\tools\create-arm-template-parameter-files.ps1 -adapCMDB $adapCMDB -paramDirectory "$armTemplatesDirectory\parameters"
  }
  exit
  
  # Remove variable
  ((Compare-Object -ReferenceObject (Get-Variable).Name -DifferenceObject $DefaultVariables).InputObject).foreach{Remove-Variable -Name $_}

  # Completing Deployment of Azure Assets
  Write-Verbose -Message ('Completing deployment of Azure Assets') -Verbose
