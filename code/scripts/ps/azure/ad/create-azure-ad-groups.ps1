<#
    .SYNOPSIS
        Create groups in Azure Active Directory

    .DESCRIPTION
        This script will create users and groups from an Excel file into Azure Active Directory

    .PARAM
        $adapCMDB - Excel Spreadsheet CMDB

    .EXAMPLE
        .\create-azure-ad-groups.ps1 -$adapCMDB adap-cmdb.xlsx

    .NOTES
        AUTHOR: [Author]
        LASTEDIT: August 18, 2019
#>
param(
    [string]$adapCMDB                     = $adapCMDB,
    [ValidateSet("create","purge")]$action= "create"
    )


# ====================
# Begin Script
# ====================
$SepChar = '|'

## Process Worksheet
# Load list of Groups from Worksheet
$cmdbExcel = Open-Excel
$wb = Get-Workbook -ObjExcel $cmdbExcel -Path "$adapCMDB"
$ws = Get-Worksheet -Workbook $wb -SheetName "A-ADGroups"
$ListofGroups = Get-WorksheetData -Worksheet $ws

foreach ($U in $ListofGroups)
{
        if ($U.GroupName)
        {
      $GroupName     = $U.GroupName.Split($SepChar)
      $GDescription  = $U.GroupDescription.Split($SepChar)
      $GDisplayName  = $U.GroupDisplayName.Split($SepChar)
      $GMailEnabled  = $U.G_MailEnabled.Split($SepChar) | % { $_ -eq 'Yes'}
      $GSecEnabled   = $U.G_SecurityEnabled.Split($SepChar) | % { $_ -eq 'Yes'}
      $mailNickName  = "NotSet"

            for ($i=0;$i -lt $GroupName.Length; $i++)
            {
                $ThisGroup = Get-AzureADGroup -SearchString $GroupName[$i]
                if (-not $ThisGroup)
                {
                  if ($action -eq 'create')
                  {
                    write-host -foreground CYAN  "Creating group $($Groupname[$i]) $($Gdescription[$i]) "
                    write-host new-azureadgroup -displayname  $GroupName[$i] -description $Gdescription[$i] -MailEnabled $GMailEnabled[$i]  -SecurityEnabled $GSecEnabled[$i] -mailnickname $mailNickName
                    $ThisGroup = new-azureadgroup -displayname  $GroupName[$i] -description $Gdescription[$i] -MailEnabled $GMailEnabled[$i]  -SecurityEnabled $GSecEnabled[$i] -mailnickname $mailNickName
                  }
                }
                else
                {
                  if ($action -eq 'purge')
                  {
                    write-host -foreground CYAN  "Deleting group $($Groupname[$i]) $($Gdescription[$i]) "
                    write-host remove-azureadgroup -ObjectId  $ThisGroup.ObjectId
                    remove-azureadgroup -ObjectId  $ThisGroup.ObjectId
                  }
                }
            }
        }
    }