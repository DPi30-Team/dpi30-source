<#
    .SYNOPSIS
        Create users in Azure Active Directory

    .DESCRIPTION
        This script will create users from an Excel file into Azure Active Directory

    .PARAM
        $adapCMDB - Excel Spreadsheet CMDB

    .EXAMPLE
        .\create-azure-ad-users.ps1 -$adapCMDB adap-cmdb.xlsx

    .NOTES
        AUTHOR: [Author]
        LASTEDIT: August 18, 2017
#>
[CmdletBinding()]
param(
    [string]$adapCMDB                       = $adapCMDB,
    [string]$action                       = "create"
	)


# ====================
# Begin Script
# ====================
$SepChar = '|'

Add-Type -AssemblyName Microsoft.Open.AzureAD16.Graph.Client

Write-Verbose -Message "Checking Azure Environment $azureEnvironment...."
if ( ( Get-AzEnvironment | Where-Object Name -match $azureEnvironment ) -eq $NULL)
{
        Write-Verbose -Message "The Azure Environment $azureEnvironment does not exist. Pls specify an existing Azure environment"
        return
}

## Process Worksheet
# Load list of Users from Worksheet
$cmdbExcel = Open-Excel
$wb = Get-Workbook -ObjExcel $cmdbExcel -Path "$adapCMDB"
$ws = Get-Worksheet -Workbook $wb -SheetName "A-ADUsers"
$ListofUsers = Get-WorksheetData -Worksheet $ws

foreach ($U in $ListofUsers)
{
        if ($U.UserPrincipalName)
        {
		  $UserPrincipalName     = $U.UserPrincipalName.Split($SepChar)
		  $DisplayName  = $U.DisplayName.Split($SepChar)
		  $Enabled  = $true
		  $FirstName  = $U.FirstName.Split($SepChar)
		  $LastName  = $U.LastName.Split($SepChar)
		  $City  = $U.City.Split($SepChar)
		  $Street  = $U.Street.Split($SepChar)
		  $PhoneNumber  = $U.PhoneNumber.Split($SepChar)
		  $MobilePhone  = $U.MobilePhone.Split($SepChar)
		  $Department  = $U.Department.Split($SepChar)
		  $ForceChangePasswordNextLogin  = $true
		  $ShowInAddressList  = $true

            for ($i=0;$i -lt $UserPrincipalName.Length; $i++)
            {
                $ThisUser = Get-AzureADUser -ObjectId $UserPrincipalName[$i]
                if (-not $ThisUser)
                {
                  if ($action -eq 'create')
                  {
                    write-host -foreground CYAN  "Creating User $($UserPrincipalName[$i]) $($DisplayName[$i]) "
                    write-host  New-AADUser -UserPrincipalName $UserPrincipalName[$i] -DisplayName $DisplayName[$i] -Enabled $Enabled[$i] -FirstName $FirstName[$i] -LastName $lastName[$i] -City "$City[$i]" -Street "$Street[$i]" -PhoneNumber $PhoneNumber[$i] -MobilePhone $MobilePhone[$i] -Department $Department[$i] -ForceChangePasswordNextLogin $ForceChangePasswordNextLogin[$i] -ShowInAddressList $ShowInAddressList[$i]
                    $ThisUser = New-AADUser -UserPrincipalName $UserPrincipalName[$i] -Password "Z1!xcvbnm" -DisplayName $DisplayName[$i] -Enabled $Enabled[$i] -FirstName $FirstName[$i] -LastName $LastName[$i] -City $City[$i] -Street $Street[$i] -PhoneNumber $PhoneNumber[$i] -MobilePhone $MobilePhone[$i] -Department $Department[$i] -ForceChangePasswordNextLogin $ForceChangePasswordNextLogin[$i] -ShowInAddressList $ShowInAddressList[$i]
                  }
                }
                else
                {
                  if ($action -eq 'purge')
                  {
                    write-host -foreground CYAN  "Deleting User $($UserPrincipalName[$i]) $($DisplayName[$i]) "
                    write-host Remove-AADUser -ObjectId  $UserPrincipalName
                    Remove-AADUser -ObjectId  $UserPrincipalName
                  }
                }
            }
        }
    }