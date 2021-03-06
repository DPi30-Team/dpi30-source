﻿<#
    .SYNOPSIS
    If not currently logged in to Azure, prompts for login and selection of subscription to use.
#>
function Initialize-Subscription
{
  param(
    # Force requires the user selects a subscription explicitly
    [parameter(Mandatory=$false)]
    [switch] $Force=$false,

    # NoEcho stops the output of the signed in user to prevent double echo
    [parameter(Mandatory=$false)]
    [switch] $NoEcho
  )

  If(!$Force)
  {
    try
    {
      # Use previous login credentials if already logged in
      $AzureContext = Get-AzContext

      if (!$AzureContext.Account)
      {
        # Fall through and require login
      }
      else
      {
        # Don't display subscription details if already logged in
        if (!$NoEcho)
        {
          $subscriptionId = Get-SubscriptionId
          $subscriptionName = Get-SubscriptionName
          $tenantId = Get-TenantId
          Write-Output "Signed-in as $($AzureContext.Account), Subscription '$($subscriptionId)' '$($subscriptionName)', Tenant Id '$($tenantId)'"
        }
        return
      }
    }
    catch
    {
      # Fall through and require login - (Get-AzContext fails with Az. modules < 4.0 if there is no logged in acount)
    }
  }
  #Login to Azure
  Connect-AzAccount
  $Azurecontext = Get-AzContext
  Write-Output "You are signed-in as: $($Azurecontext.Account)"

  # Get subscription list
  $subscriptionList = Get-SubscriptionList
  if($subscriptionList.Length -lt 1)
  {
    Write-Error "Your Azure account does not have any active subscriptions. Exiting..."
    exit
  }
  elseif($subscriptionList.Length -eq 1)
  {
    Set-AzContext -SubscriptionId $subscriptionList[0].Id > $null
  }
  elseif($subscriptionList.Length -gt 1)
  {
    # Display available subscriptions
    $index = 1
    foreach($subscription in $subscriptionList)
    {
      $subscription | Add-Member -type NoteProperty -name "Row" -value $index
      $index++
    }

    # Prompt for selection
    Write-Output "Your Azure subscriptions: "
    $subscriptionList | Format-Table Row, Id, Name -AutoSize

    # Select single Azure subscription for session
    try
    {
      [int]$selectedRow = Read-Host "Enter the row number to select the subscription to use" -ErrorAction Stop

      Set-AzContext -SubscriptionId $subscriptionList[($selectedRow - 1)] -ErrorAction Stop > $null

      Write-Output "Subscription Id '$($subscriptionList[($selectedRow - 1)].Id)' selected."
    }
    catch
    {
      Write-Error 'Invalid selection. Exiting...'
      exit
    }
  }
}

function Get-SubscriptionId
{
  $Azurecontext = Get-AzContext
  if ($Azurecontext) {
    return (Get-AzContext).Subscription.Id
  }
  else {
    Write-Host "No current Azure Context"
  }
}

function Get-SubscriptionName
{
  $Azurecontext = Get-AzContext
  if ($Azurecontext) {
      return (Get-AzContext).Subscription.Name
  }
  else {
    Write-Host "No current Azure Context"
  }
}

function Get-TenantId
{
  $Azurecontext = Get-AzContext
  if ($Azurecontext) {
      return (Get-AzContext).Tenant.Id
  }
  else {
    Write-Host "No current Azure Context"
  }
}

function Get-SubscriptionList
{

  # Add 'id' and 'name' properties to subscription object returned for Az. modules less than 4.0
  $subscriptionObject = Get-AzSubscription

  foreach ($subscription in $subscriptionObject)
  {
    $subscription | Add-Member -type NoteProperty -name "Id" -Value $($subscription.SubscriptionId)
    $subscription | Add-Member -type NoteProperty -Name "Name" -Value $($subscription.SubscriptionName)
  }

  return $subscriptionObject

}

function Get-DbId
{
  $Azurecontext = Get-AzContext
  $AzureModuleVersion = Get-Module Az.Resources -list

  # Check PowerShell version to accommodate breaking change in Az. modules greater than 4.0
  if ($AzureModuleVersion.Version.Major -ge 4)
  {
    return $Azurecontext.Db.Id
  }
  else
  {
    return $Azurecontext.Db.DbId
  }
}

<#
    .SYNOPSIS
    Tests if a db key is registered. Returns true if the key exists in the catalog (whether on-line or off-line) or false if it does not.
#>
function Test-ResourceGroupExists
{
  param(
    [parameter(Mandatory=$true)]
    [string] $ResourceGroupName
  )

  try
  {
    Get-AzResourceGroup -Name $ResourceGroupName
    return $true
  }
  catch
  {
    return $false
  }
}

function Remove-ResourceGroup
{
  param(
    [parameter(Mandatory=$true)]
    [string] $Name
  )

  try
  {
    $rgexists = Get-AzResourceGroup $Name
    if ($rgexists) {
      Remove-AzResourceGroup -Name $Name -Force -Verbose
      $rgexists=$false
    }
  }
  catch
  {
    Write-Error "An error occurred during RG removal."
    throw
  }
}

function Get-PSModules
{     <#
      .SYNOPSIS
        Checks for required PS Modules

      .EXAMPLE

    #>
  ## Install ImportExcel module
  if ( -not (get-module -listavailable | Where-Object name -match 'ImportExcel'))
  {
    Install-Module -Name ImportExcel -force -AllowClobber -confirm:$false
  }
  else
  {
    Import-Module ImportExcel -verbose:0 -ErrorAction SilentlyContinue
  }

  ## Install Azure AD
  if ( -not (get-module -listavailable | Where-Object name -match 'AzureAD'))
  {
    install-Module AzureAD -force -AllowClobber -confirm:$false
  }
    else
  {
    Import-Module AzureAD -verbose:0 -ErrorAction SilentlyContinue
  }

  ## Install Az module
  if ( -not (get-module -listavailable | Where-Object name -match 'Az'))
  {
    Install-Module -Name Az -force -AllowClobber -confirm:$false
  }
      else
  {
    Import-Module Az -verbose:0 -ErrorAction SilentlyContinue
  }

}

function Open-Excel {
  <#
      .SYNOPSIS
      This advanced function opens an instance of the Microsoft Excel application.

      .DESCRIPTION
      The function opens an instance of Microsoft Excel but keeps it hidden unless the Visible parameter is used.

      .PARAMETER Visible
      The parameter switch Visible when specified will make Excel visible on the desktop.

      .EXAMPLE
      The example below returns the Excel COM object when used.

      Open-Excel [-Visible] [-DisplayAlerts] [-AskToUpdateLinks]

      PS C:\> $myObjExcel = Open-Excel

      or

      PS C:\> $myObjExcel = Open-Excel -Visible

      .NOTES    
    
    
  #>
  [cmdletbinding()]
    Param (
            [Parameter(Mandatory = $false,
                ValueFromPipeline = $true,
                ValueFromPipelineByPropertyName = $true)]
                [Switch]$Visible = $false,
            [Parameter(Mandatory = $false,
                ValueFromPipeline = $true,
                ValueFromPipelineByPropertyName = $true)]
                [Switch]$DisplayAlerts = $false,
            [Parameter(Mandatory = $false,
                ValueFromPipeline = $true,
                ValueFromPipelineByPropertyName = $true)]
                [Switch]$AskToUpdateLinks = $false
        )
    Begin {
            # Create an Object Excel.Application using Com interface
            $objExcel = New-Object -ComObject Excel.Application
        }
    Process {
            # Disable the 'visible' property if not specified.
            $objExcel.Visible = $Visible
            # Disable the 'DisplayAlerts' property if not specified.
            $objExcel.DisplayAlerts = $DisplayAlerts
            # Disable the 'AskToUpdateLinks' property if not specified.
            $objExcel.AskToUpdateLinks = $AskToUpdateLinks
    }
    End {
            # Return the Excel COM object.
      Return $objExcel
    }
}

function Close-Excel {
    <#
      .SYNOPSIS
        This advanced function closes Excel ending all related objects.

      .DESCRIPTION
        The function closes the Excel and releases the COM Object, Workbook, and Worksheet, then cleans up the instance of Excel.

      .PARAMETER ObjExcel
        The mandatory parameter ObjExcel is the Excel COM Object passed to the function.

      .EXAMPLE
        The example below closes the excel instance defined by the COM Objects from the parameter section.

        Close-Excel -ObjExcel <PS Excel COM Object>

        PS C:\> Close-Excel -ObjExcel $myObjExcel

      .NOTES
        
        
        
    #>
    [cmdletbinding()]
        Param (
            [Parameter(Mandatory = $true,
                ValueFromPipeline = $true,
                ValueFromPipelineByPropertyName = $true)]
                [ValidateScript({$_.GetType().FullName -eq "Microsoft.Office.Interop.Excel.ApplicationClass"})]
                $ObjExcel)
        Begin {
            # Define a workbook array.
            $workbooks = @()
            # Define a worksheet array.
            $worksheets = @()
        }
        Process {
            ForEach ($workbook in $ObjExcel.Workbooks) {
                # Add the workbook COM objects to the workbook array.
                $workbooks += $workbook
                # Add the worksheet COM objects to the worksheet array.
                $worksheets += $workbook.Sheets.Item($workbook.ActiveSheet.Name)
                # Close the current worksheet.
                $workbook.Close($false)
            }
            # Quit the Excel Object.
            $ObjExcel.Quit()
        }
        End {
            # Release all the worksheet COM Ojbects.
            Foreach ($w in $worksheets) {
                [void][System.Runtime.Interopservices.Marshal]::FinalReleaseComObject($w)
            }
            # Release all the workbook COM Objects.
            Foreach ($w in $workbooks) {
                [void][System.Runtime.Interopservices.Marshal]::FinalReleaseComObject($w)
            }

            # Release the Excel COM Object.
            [void][System.Runtime.Interopservices.Marshal]::FinalReleaseComObject($ObjExcel)
            # Forces an immediate garbage collection of all generations.
            [System.GC]::Collect()
            # Suspends the current thread until the thread that is processing the queue of finalizers has emptied that queue.
            [System.GC]::WaitForPendingFinalizers()
        }
}

function Get-Workbook {
    <#
      .SYNOPSIS
        This advanced function creates returns a Microsoft Excel Workbook COM Object.

      .DESCRIPTION
        Given the Microsoft Excel COM Object and Path to the Excel file, the function retuns the Workbook COM Object.

      .PARAMETER ObjExcel
        The mandatory parameter ObjExcel is the Excel COM Object passed to the function.

      .PARAMETER Path
        The mandatory parameter Path is the location string of the Excel file. Relative and Absolute paths are supported.

      .EXAMPLE
        The example below returns the workbook COM object specified by Path.

        Get-Workbook -ObjExcel [-Path <String>]

        PS C:\> $wb = Get-Workbook -ObjExcel $myExcelObj -Path "C:\Excel.xlsx"

      .NOTES
        
        
       
    #>
    [cmdletbinding()]
        Param (
            [Parameter(Mandatory = $true,
                ValueFromPipeline = $true,
                ValueFromPipelineByPropertyName = $true)]
                [ValidateScript({$_.GetType().FullName -eq "Microsoft.Office.Interop.Excel.ApplicationClass"})]
                $ObjExcel,
            [Parameter(Mandatory = $false,
                ValueFromPipeline = $true,
                ValueFromPipelineByPropertyName = $true)]
                [ValidateScript({Test-Path $_})]
                [String]$Path)
        Begin {
            # If no path was specified, prompt for path until it has a value.
            if (-not $Path) {
                $Path = Read-FilePath -Title "Select Microsoft Excel Workbook to Import" -Extension xls,xlsx
                if (-not $Path) {Return "Error, Workbook not specified."}
            }
            # Check to make sure the file is either a xls or xlsx file.
            if ((Get-ChildItem -Path $Path).Extension -notmatch "xls") {
                Return {"File is not an excel file. Please select a valid .xls or .xlsx file."}
            }
            # Check to see if the path is relative or absolute. A rooted path is absolute.
            if (-not [System.IO.Path]::IsPathRooted($Path)) {
                # Resolve absolute path from relative path.
                $Path = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($Path)
            }
        }
        Process {
            # Open the Excel workbook found at location specified in the Path variable.
            $workbook = $ObjExcel.Workbooks.Open($Path)
        }
        End {
            # Return the workbook COM object.
            Return $workbook
        }
}

function Get-Worksheet {
    <#
      .SYNOPSIS
        This advanced function returns a named Microsoft Excel Worksheet.

      .DESCRIPTION
        This function returns the Worksheet COM Object specified by the Workbook and Sheetname.

      .PARAMETER Workbook
        The mandatory parameter Workbook is the workbook COM Object passed to the function.

      .PARAMETER Sheetname
        The mandatory parameter Sheetname is the name of the worksheet returned.

      .EXAMPLE
        The example below returns the named "Sheet1" worksheet COM Object.

        Get-Worksheet -Workbook <PS Excel Workbook COM Object> -SheetName <String>

        PS C:\> $ws = Get-Worksheet -Workbook $wb -SheetName "Sheet1"

      .NOTES
        
        
        
    #>
    [cmdletbinding()]
        Param (
            [Parameter(Mandatory = $true,
                ValueFromPipeline = $true,
                ValueFromPipelineByPropertyName = $true)]
                [ValidateScript({$_.GetType().IsCOMObject})]
                $Workbook,
            [Parameter(Mandatory = $true,
                ValueFromPipeline = $true,
                ValueFromPipelineByPropertyName = $true)]
                [ValidateScript({($Workbook.Worksheets | Select-Object Name).Name -Contains $_})]
                [string]$SheetName)
        Begin {
            # Activate the current Excel workbook.
            $Workbook.Activate()
        }
        Process {
            # Get the worksheet COM object specified by the SheetName string variable.
            $worksheet = $Workbook.Sheets.Item($SheetName)
        }
        End {
            # Return the Excel worksheet COM object.
            Return $worksheet
        }
}

function Add-Worksheet {
    <#
      .SYNOPSIS
        This advanced function creates a new worksheet.

      .DESCRIPTION
        This function creates a new worksheet in the given workbook. if a Sheetname is specified it renames the
      new worksheet to that name.

      .PARAMETER ObjExcel
        The mandatory parameter ObjExcel is the Excel COM Object passed to the function.

      .PARAMETER Workbook
        The mandatory parameter Workbook is the workbook COM Object passed to the function.

      .PARAMETER Sheetname
        The optional parameter Sheetname is a string passed to the function to name the newly created worksheet.

      .EXAMPLE
        The example below creates a new worksheet named Data.

        Add-Worksheet -ObjExcel <PS Excel COM Object> -Workbook <PS Excel COM Workbook Object> [-SheetName <String>]

        PS C:\> Add-Worksheet -ObjExcel $myObjExcel -Workbook $wb -Sheetname "Data"

      .NOTES
        
        
       
    #>
    [cmdletbinding()]
        Param (
            [Parameter(Mandatory = $true,
                ValueFromPipeline = $true,
                ValueFromPipelineByPropertyName = $true)]
                [ValidateScript({$_.GetType().FullName -eq "Microsoft.Office.Interop.Excel.ApplicationClass"})]
                $ObjExcel,
            [Parameter(Mandatory = $true,
                ValueFromPipeline = $true,
                ValueFromPipelineByPropertyName = $true)]
                [ValidateScript({$_.GetType().IsCOMObject})]
                $Workbook,
            [Parameter(Mandatory = $false,
                ValueFromPipeline = $true,
                ValueFromPipelineByPropertyName = $true)]
                [ValidateScript({(Get-WorksheetNames -Workbook $Workbook) -NotContains $_})]
                [string]$SheetName)
        Begin {
            # http://www.planetcobalt.net/sdb/vba2psh.shtml
            $def = [Type]::Missing
            # Activate the current Excel workbook.
            $Workbook.Activate()
        }
        Process {
            # Add a single worksheet to the current workbook.
            $worksheet = $ObjExcel.Worksheets.Add($def,$def,1,$def)
            # If the SheetName variable is specified, rename the new worksheet.
            if ($SheetName) {
                $worksheet.Name = $SheetName
            }
        }
        End {
            # Return the updated Excel workbook COM object.
            Return $workbook
        }
}

function Add-Workbook {
    <#
      .SYNOPSIS
        This advanced function creates returns a Microsoft Excel Workbook COM Object.

      .DESCRIPTION
        Given the Microsoft Excel COM Object and Path to the Excel file, the function retuns the Workbook COM Object.

      .PARAMETER ObjExcel
        The mandatory parameter ObjExcel is needed to retrieve the Workbook COM Object.

      .EXAMPLE
        The example below returns the newly created Excel workbook COM Object.

        Add-Workbook -ObjExcel <PS Excel COM Object>

        PS C:\> Add-Workbook -ObjExcel $myExcelObj

      .NOTES
        
        
        
    #>
        [cmdletbinding()]
            Param (
                [Parameter(Mandatory = $true,
                    ValueFromPipeline = $true,
                    ValueFromPipelineByPropertyName = $true)]
                    [ValidateScript({$_.GetType().FullName -eq "Microsoft.Office.Interop.Excel.ApplicationClass"})]
                    $ObjExcel)
            Begin {}
            Process {
                # Add a new workbook to the current Excel COM object.
                $workbook = $ObjExcel.Workbooks.Add()
            }
            End {
                # Return the updated Excel workbook COM object.
                Return $workbook
            }
}

function Save-Workbook {
    <#
      .SYNOPSIS
        This advanced function saves the Microsoft Excel Workbook.

      .DESCRIPTION
        This advanced function saves the Microsoft Excel Workbook. if a Path is specified it does a SaveAs, otherwise
      it just saves the data.

      .PARAMETER Path
        The mandatory parameter Path is the location string of the Excel file.

      .PARAMETER Workbook
        The mandatory parameter Workbook is the workbook COM Object passed to the function.

      .EXAMPLE
        The example below Saves the workbook as C:\Excel.xlsx.

        Save-Workbook -Workbook <PS Excel COM Workbook Object> -Path <String>

        PS C:\> Save-Workbook -Workbook $wb -Path "C:\Excel.xlsx"

      .NOTES
        
        
        
    #>
        [cmdletbinding()]
            Param (
                [Parameter(Mandatory = $true,
                    ValueFromPipeline = $true,
                    ValueFromPipelineByPropertyName = $true)]
                    [ValidateScript({$_.GetType().IsCOMObject})]
                    $Workbook,
                [Parameter(Mandatory = $true,
                    ValueFromPipeline = $true,
                    ValueFromPipelineByPropertyName = $true)]
                    [String]$Path)
            Begin {
                # Add Excel namespace
                Add-Type -AssemblyName Microsoft.Office.Interop.Excel
                # Specify file format when saving excel - Open XML Workbook
                $xlFixedFormat = [Microsoft.Office.Interop.Excel.XlFileFormat]::xlOpenXMLWorkbook

                # Check to see if the path is relative or absolute. A rooted path is absolute.
                if (-not [System.IO.Path]::IsPathRooted($Path)) {
                    # Resolve absolute path from relative path.
                    $Path = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($Path)
                    # Activate the current workbook.
                    $Workbook.Activate()
                }
            }
            Process {
                # If a path was specified proceed with a save as.
                if ($Path) {
                    $workbook.SaveAs($Path,$xlFixedFormat)
                }
                # Check if a path is indicated in the workbook object properties.
                elseif ($Workbook.Path) {
                    # Save the workbook to the path from the workbook object properties.
                    $Workbook.Save()
                }
                else {
                    # Write error to indicate a path must be specified if the workbook was created by this module and has not been previously saved.
                    Write-Error "Workbook has never been saved before, please provide a valid path."
                }
            }
            End {}
}

function Get-WorksheetUsedRange {
    <#
      .SYNOPSIS
        This advanced function returns the Column and Row of the used range in a Worksheet.

      .DESCRIPTION
        This advanced function returns a hashtable containing the last used column and last used row of a worksheet.

      .PARAMETER Worksheet
        The mandatory parameter Worksheet is the Excel worksheet com object passed to the function.

      .EXAMPLE
        The example below returns a hashtable containing the last used column and row of the referenced worksheet.

        Get-WorksheetUsedRange -Worksheet <PS Excel Worksheet Object>

        PS C:\> Get-WorksheetUsedRange -Worksheet $myWorksheet

      .NOTES
        There are several ways to get the used range in an Excel Worksheet. However, most of them will return areas
        in which formatting has been appied or changed. This method looks for the last column and row where a cell has a value.
        See https://blog.udemy.com/excel-vba-find/ for details.

        
        
    #>
    [cmdletbinding()]
        Param (
            [Parameter(Mandatory = $true,
                ValueFromPipeline = $true,
                ValueFromPipelineByPropertyName = $true)]
                [ValidateScript({$_.GetType().IsCOMObject})]
                $worksheet)
        Begin {
            # Define search parameters, see https://blog.udemy.com/excel-vba-find/ for details.
            # What (required): The only required parameter, What tells the Excel what to actually look for. This can be anything - string, integer, etc.).
            $What = "*"
            # After (optional): This specifies the cell after which the search is to begin. This must always be a single cell; you can't use a range here.
            # If the after parameter isn't specified, the search begins from the top-left corner of the cell range.
            $After = $worksheet.Range("A1")
            # LookIn (optional): This tells Excel what type of data to look in, such as xlFormulas.
            $LookIn = [Microsoft.Office.Interop.Excel.XlFindLookIn]::xlValues
            # LookAt (optional): This tells Excel whether to look at the whole set of data, or only a selected part. It can take two values: xlWhole and xlPart
            $LookAt = [Microsoft.Office.Interop.Excel.xllookat]::xlPart
            # SearchDirection(optional): This is used to specify whether Excel should search for the next or the previous matching value. You can use either xlNext
            # (to search for next matches) or xlPrevious (to search for previous matches).
            $XlSearchDirection = [Microsoft.Office.Interop.Excel.XlSearchDirection]::xlPrevious
            # MatchCase(optional): Self-explanatory; this tells Excel whether it should match case when doing the search or not. The default value is False.
            $MatchCase = $False
            # MatchByte(optional): This is used if you have installed double-type character set (DBCS). Understanding DBCS is beyond the scope of this tutorial.
            # Like MatchCase, this can also have two values: True or False, with default being False.
            $MatchByte = $False
            # SearchFormat(optional): This parameter is used when you want to select cells with a specified property. It is used in conjunction with the FindFormat
            # property. Say, you have a list of cells where one particular cell (or cell range) is in Italics. You could use the FindFormat property and set it to
            # Italics. If you later use the SearchFormat parameter in Find, it will select the Italicized cell.
            $SearchFormat = [Type]::Missing
            # Define an ordered hashtable.
            $hashtable = [ordered]@{}
        }
        Process {
            # Set the search order to be by columns.
            $SearchOrder = [Microsoft.Office.Interop.Excel.XlSearchOrder]::xlByColumns
            # Return the address of the last used column cell with data in it.
            $hashtable["Column"] = $worksheet.Cells.Find($What, $After, $LookIn, $LookAt, $SearchOrder, $XlSearchDirection, $MatchCase, $MatchByte, $SearchFormat).Column
            # Set the search order to be by rows.
            $SearchOrder = [Microsoft.Office.Interop.Excel.XlSearchOrder]::xlByRows
            # Return the address of the last used row cell with data in it.
            $hashtable["Row"] = $worksheet.Cells.Find($What, $After, $LookIn, $LookAt, $SearchOrder, $XlSearchDirection, $MatchCase, $MatchByte, $SearchFormat).Row
        }
        End {
            # Release the Excel Range COM Object.
            [System.Runtime.InteropServices.Marshal]::ReleaseComObject($After)
            # Return the result hashtable.
            Return $hashtable
        }
}

function Get-WorksheetData {
    <#
      .SYNOPSIS
        This advanced function creates an array of pscustom objects from an Microsoft Excel worksheet.

      .DESCRIPTION
        This advanced function creates an array of pscustom objects from an Microsoft Excel worksheet.
        The first row will be used as the object members and each additional row will form the object data for that member.

      .PARAMETER Worksheet
        The parameter Worksheet is the Excel worksheet com object passed to the function.

      .PARAMETER HashtableReturn
        The optional switch parameter HashtableReturn with default value False, causes the function to return an array of
      hashtables instead of an array of objects.

      .PARAMETER TrimHeaders
        The optional switch parameter TrimHeaders, removes whitespace from the column headers when creating the object or hashtable.

      .EXAMPLE
        The example below returns an array of custom objects using the first row as object parameter names and each
      additional row as object data.

        Get-WorksheetData -Worksheet <PS Excel Worksheet COM Object> [-HashtableReturn] [-TrimHeaders]

        PS C:\> Get-WorksheetData -Worksheet $myWorksheet

      .NOTES

    #>
    [cmdletbinding()]
        Param (
            [Parameter(Mandatory = $true,
                ValueFromPipeline = $true,
                ValueFromPipelineByPropertyName = $true)]
                [ValidateScript({($_.UsedRange.SpecialCells(11).row -ge 2) -and $_.GetType().IsCOMObject})]
                $worksheet,
            [Parameter(Mandatory = $false,
                ValueFromPipeline = $true,
                ValueFromPipelineByPropertyName = $true)]
                [Switch]$HashtableReturn = $false,
            [Parameter(Mandatory = $false,
                ValueFromPipeline = $true,
                ValueFromPipelineByPropertyName = $true)]
                [Switch]$TrimHeaders = $false
        )
        Begin {
            $usedRange = Get-WorksheetUsedRange -worksheet $worksheet

            # Addressing in $worksheet.cells.item(Row,Column)
            # Get the Address of the last column on the worksheet.
            $lastColumnAddress = $workSheet.Cells.Item(1,$usedRange.Column).address()
            # Get the Address of the last row on the worksheet.
            $lastColumnRowAddress = $workSheet.Cells.Item($usedRange.Row,$usedRange.Column).address()
            # Get the values of the first row to use as object Properties. Replace "" with "" to convert to a one dimensional array.
            $headers = $workSheet.Range("A1",$lastColumnAddress).Value() -replace "",""
            # If $TrimHeaders is true, remove whitespce from the headers.
            # https://stackoverflow.com/questions/24355760/removing-spaces-from-a-variable-input-using-powershell-4-0
            # To remove all spaces at the beginning and end of the line, and replace all double-and-more-spaces or tab symbols to space-bar symbol.
            if ($TrimHeaders.IsPresent) {
                $headers = $headers -replace '(^\s+|\s+$)','' -replace '\s+',''
            }
            # Get the values of the remaining rows to use as object values.
            $data	= $workSheet.Range("A2",$lastColumnRowAddress).Value()
            # Define the return array.
            $returnArray = @()
        }
        Process {
            for ($i = 1; $i -lt $UsedRange.Row; $i++)
                {
                    # Define an Ordered hashtable.
                    $hashtable = [ordered]@{}
                    for ($j = 1; $j -le $UsedRange.Column; $j++)
                    {
                        # If there is more than one column.
                        if ($UsedRange.Column -ne 1) {
                            # Then add a key value to the current hashtable. Where the key (i.e. header) is in row 1 and column $j and the value (i.e. data) is in row $i and column $j.
                            $hashtable[$headers[$j-1]] = $data[$i,$j]
                        }
                        # If is only one column and there are more than two rows.
                        elseif ($UsedRange.Row -gt 2) {
                            # Then add a key value to the current hashtable. Where the key (i.e. header) is just the header (row 1, column 1) and the value is in row $i and column 1.
                            $hashtable[$headers] = $data[$i,1]
                        }
                        # If there is only there is only one column and two rows.
                        else {
                            # Then add a key value to the current hashtable. Where the key (i.e. header) is just the header (row 1, column 1) and the value is in row 2 and column 1.
                            $hashtable[$headers] = $data
                        }
                    }
                    # Add Worksheet NoteProperty Item to Hashtable.
                    $hashtable["WorkSheet"] = $workSheet.Name
                    # If the HashtableReturn switch has been selected, add the hashtable to the return array.
                    if ($HashtableReturn) {
                        $returnArray += $hashtable
                    }
                    else {
                        # If the HashtableReturn switch is $false (Default), convert the hashtable to a custom object and add it to the return array.
                        $returnArray += [pscustomobject]$hashtable
                    }
                }
        }
        End {
            # return the array of hashtables or custom objects.
            Return $returnArray
        }
}

function Set-WorksheetData {
    <#
      .SYNOPSIS
        This advanced function populates a Microsoft Excel Worksheet with data from an Array of custom objects or hashtables.

      .DESCRIPTION
        This advanced function populates a Microsoft Excel Worksheet with data from an Array of custom objects. The object
      members populates the first row of the sheet as header items. The object values are placed beneath the headers on
      each successive row.

      .PARAMETER Worksheet
        The mandatory parameter Worksheet is the Excel worksheet com object passed to the function.

      .PARAMETER InputArray
        The mandatory parameter InputArray is an Array of custom objects.

      .EXAMPLE
        The example below returns an array of custom objects using the first row as object parameter names and each additional
      row as object data.

        Set-WorksheetData -Worksheet <PS Excel Worksheet COM Object> -InputArray <PS Object Array>

        PS C:\> Set-WorksheetData -Worksheet $Worksheet -ImputArray $myObjectArray

      .NOTES

    #>
    [cmdletbinding()]
        Param (
            [Parameter(Mandatory = $true,
                ValueFromPipeline = $true,
                ValueFromPipelineByPropertyName = $true)]
                [ValidateScript({$_.GetType().IsCOMObject})]
                $worksheet,
            [Parameter(Mandatory = $true,
                ValueFromPipeline = $true,
                ValueFromPipelineByPropertyName = $true)]
                $InputArray)
        Begin {
            # Convert an input hashtables to pscustomobjects
            if ($InputArray[0] -is "Hashtable") {
                $InputArray = $InputArray | ForEach-Object {[pscustomobject]$_}
            }
        }
        Process {
            $properties = $InputArray[0].PSObject.Properties
            # Number of columns is equal to the header count.
            $columns = $properties.Name.Count
            # Number of rows is equal to the number of values devided by the number of headers.
            $rows = $InputArray.Count
            # Create a multidimenstional array sized number of rows by number of columns.
            $array = New-Object 'object[,]' $($rows + 1), $columns

            for ($i=0; $i -lt $rows; $i++) {
                $row = $i + 1
                for ($j=0; $j -lt $columns; $j++) {
                    if ($i -eq 0) {
                        $array[$i,$j] = $properties.Name[$j];
                    }
                    $array[$row,$j] = $InputArray[$i].$($properties.Name[$j])
                }
            }
            # Define the Excel worksheet range.
            $range = $Worksheet.Range($Worksheet.Cells(1,1), $Worksheet.Cells($($rows + 1),$columns))
            # Populate the worksheet using the Worksheet.Range function.
            $range.Value2 = $array
        }
        End {}
}

function Set-WorksheetName {
    <#
      .SYNOPSIS
        This advanced function sets the name of the given worksheet.

      .DESCRIPTION
        This advanced function sets the name of the given worksheet.

      .PARAMETER Worksheet
        The mandatory parameter Worksheet is the Excel worksheet com object passed to the function.

      .EXAMPLE
        The example below renames the worksheet to Data unless that name is already in use.

        Set-WorksheetName -Worksheet <PS Excel Worksheet COM Object> -SheetName <String>

        PS C:\> Set-WorksheetName -Worksheet $myWorksheet -SheetName "Data"

      .NOTES
        
        
        
    #>
    [cmdletbinding()]
        Param (
            [Parameter(Mandatory = $true,
                ValueFromPipeline = $true,
                ValueFromPipelineByPropertyName = $true)]
                [ValidateScript({($_.UsedRange.SpecialCells(11).row -ge 2) -and $_.GetType().IsCOMObject})]
                $worksheet,
            [Parameter(Mandatory = $true,
                ValueFromPipeline = $true,
                ValueFromPipelineByPropertyName = $true)]
                [ValidateScript({(Get-WorksheetNames -Workbook $Workbook) -NotContains $_})]
                [string]$SheetName)
        Begin {}
        Process {
            # Set the current worksheet name to the value of the SheetName string variable.
            $worksheet.Name = $SheetName
        }
        End {}
}

function Get-WorksheetNames {
    <#
      .SYNOPSIS
        This advanced function returns a list of all worksheets in a workbook.

      .DESCRIPTION
        This advanced function returns an array of strings of all worksheets in a workbook.

      .PARAMETER Workbook
        The mandatory parameter Workbook is the Excel workbook com object passed to the function.

      .EXAMPLE
        The example below renames the worksheet to Data unless that name is already in use.

        Get-WorksheetNames -Workbook <PS Excel Workbook COM Object>

        PS C:\> Get-WorksheetNames -Workbook $myWorkbook

      .NOTES
        
       
    #>
    [cmdletbinding()]
        Param (
            [Parameter(Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true)]
            [ValidateScript({$_.GetType().IsCOMObject})]
            $Workbook)
        Begin {
            # Activate the current workbook.
            $Workbook.Activate()
        }
        Process {
            # Get the names of all worksheets in the current active workbook COM object.
            $names = ($Workbook.Worksheets | Select-Object Name).Name
        }
        End {
            # Return the worksheet names as an array of strings.
            Return $names
        }
}

function ConvertTo-Hashtable {
    <#
      .SYNOPSIS
        This advanced function returns a hashtable converted from a PSObject.

      .DESCRIPTION
        This advanced function returns a hashtable converted from a PSObject and will return work with nested PSObjects.

      .PARAMETER InputObject
        The mandatory parameter InputObject is a PSObject.

      .EXAMPLE
        The example below returns a hashtable created from the myPSObject PSObject.

        ConvertTo-Hashtable -InputObject <PSObject>

        PS C:\> $myNewHash = ConvertTo-Hashtable -InputObject $myPSObject

      .NOTES
        
    #>

    param (
        [Parameter(ValueFromPipeline)]
        $InputObject)

    process
    {
        # If the inputObject is empty, return $null.
        if ($null -eq $InputObject) { return $null }

        # IF the InputObject can be iterated through and is not a string.
        if ($InputObject -is [System.Collections.IEnumerable] -and $InputObject -isnot [string])
        {
            # Call this function recursively for each object in InputObjects.
            $collection = @(
                foreach ($object in $InputObject) { ConvertTo-Hashtable $object }
            )

            Write-Output -NoEnumerate $collection
        }
        # If the InputObject is already an Object.
        elseif ($InputObject -is [psobject])
        {
            # Define an hashtable called hash.
            $hash = @{}

            # Iterate through all the properties in the PSObject.
            foreach ($property in $InputObject.PSObject.Properties)
            {
                # Add a key value pair to the hashtable and call the ConvertTo-Hashtable function on the property value.
                $hash[$property.Name] = ConvertTo-Hashtable $property.Value
            }

            # Return the hashtable.
            $hash
        }
        else
        {
            # Return the InputObject.
            $InputObject
        }
    }
}

function Export-Yaml {
    <#
      .SYNOPSIS
        This advanced function exports a Hashtable or PSObject to a Yaml file.

      .DESCRIPTION
        This advanced function exports a hashtable or PSObject to a Yaml file

      .PARAMETER InputObject
        The mandatory parameter InputObject is a hashtable or PSObject.

      .PARAMETER Path
        The mandatory parameter Path is the location string of the Yaml file.

      .EXAMPLE
        The example below returns a hashtable created from the myPSObject PSObject.

        Export-Yaml -InputObject <PSObject> -Path <String>

        PS C:\> Export-Yaml -InputObject $myHastable -FilePath "C:\myYamlFile.yml"

        or

        PS C:\> Export-Yaml -InputObject $myPSObject -FilePath "C:\myYamlFile.yml"

      .NOTES
        
        
    #>
    param (
    [Parameter(Mandatory=$true, Position=0)]
        $InputObject,
        [Parameter(Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true)]
            [String]$Path)
    begin {
        # Check to see if the path is relative or absolute. A rooted path is absolute.
        if (-not [System.IO.Path]::IsPathRooted($Path)) {
            # Resolve absolute path from relative path.
            $Path = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($Path)
            $Workbook.Activate()
        }
        # Install powershell-yaml if not already installed.
        if (-not (Get-Module -ListAvailable -Name powershell-yaml)) {
            Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Confirm:$false -Force
            Set-PSRepository -Name "PSGallery" -InstallationPolicy Trusted
            Install-Module -Name powershell-yaml -AllowClobber -Confirm:$false
        }
        # Import the powershell-yaml module.
        Import-Module powershell-yaml
    }
    process {
        # Convert the InputObject to Yaml and save it to the Path location with overwrite.
        $InputObject | ConvertTo-Yaml | Set-Content -Path $Path -Force
    }
    end {}
}

function Export-Json {
    <#
      .SYNOPSIS
        This advanced function exports a hashtable or PSObject to a Json file.

      .DESCRIPTION
        This advanced function exports a hashtable or PSObject to a Json file

      .PARAMETER InputObject
        The mandatory parameter InputObject is a hashtable or PSObject.

      .PARAMETER Path
        The mandatory parameter Path is the location string of the Json file.

      .EXAMPLE
        The example below returns a hashtable created from the myPSObject PSObject.

        Export-Json -InputObject <PSObject> -Path <String>

        PS C:\> Export-Json -InputObject $myHastable -FilePath "C:\myJsonFile.json"

        or

        PS C:\> Export-Json -InputObject $myPSObject -FilePath "C:\myJsonFile.json"

      .NOTES
        
        
    #>
    param (
    [Parameter(Mandatory=$true, Position=0)]
        $InputObject,
        [Parameter(Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true)]
            [String]$Path)
    begin {
        # Check to see if the path is relative or absolute. A rooted path is absolute.
        if (-not [System.IO.Path]::IsPathRooted($Path)) {
            # Resolve absolute path from relative path.
            $Path = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($Path)
        }
    }
    process {
        # Convert the InputObject to Json and save it to the Path location with overwrite.
        $InputObject | ConvertTo-Json | Set-Content -Path $Path -Force
    }
    end {}
}

function Import-Json {
    <#
      .SYNOPSIS
        This advanced function imports a Json file and returns a PSCustomObject.

      .DESCRIPTION
        This advanced function imports a Json file and returns a PSCustomObject.

      .PARAMETER Path
        The mandatory parameter Path is the location string of the Json file.

      .EXAMPLE
        The example below returns a pscustomobject created from the contents of C:\myJasonFile.json.

        Import-Json -Path <String>

        PS C:\> Import-Json -Path "C:\myJsonFile.json"

      .NOTES
        
        
    #>
    param (
        [Parameter(Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true)]
            [String]$Path)
    begin {
        if (-not [System.IO.Path]::IsPathRooted($Path)) {
            # Resolve absolute path from relative path.
            $Path = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($Path)
        }
    }
    process {
        # Load the raw content from the Path provided file and convert it from Json.
        $InputObject = Get-Content -Raw -Path $Path | ConvertFrom-Json
    }
    end {
        # Return the result set as an array of PSCustom Objects.
        Return $InputObject
    }
}

function Import-Yaml {
    <#
      .SYNOPSIS
        This advanced function imports a Yaml file and returns a PSCustomObject.

      .DESCRIPTION
        This advanced function imports a Yaml file and returns a PSCustomObject.

      .PARAMETER Path
        The mandatory parameter Path is the location string of the Yaml file.

      .EXAMPLE
        The example below returns a pscustomobject created from the contents of C:\myYamlFile.yml.

        Import-Yaml -Path <String>

        PS C:\> Import-Yaml -Path "C:\myYamlFile.yml"

      .NOTES
        
        
    #>
    param (
        [Parameter(Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true)]
            [String]$Path)
    begin {
        if (-not [System.IO.Path]::IsPathRooted($Path)) {
            # Resolve absolute path from relative path.
            $Path = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($Path)
        }
        # Install powershell-yaml if not already installed.
        if (-not (Get-Module -ListAvailable -Name powershell-yaml)) {
            Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Confirm:$false -Force
            Set-PSRepository -Name "PSGallery" -InstallationPolicy Trusted
            Install-Module -Name powershell-yaml -AllowClobber -Confirm:$false
        }
        # Import the powershell-yaml module.
        Import-Module powershell-yaml
    }
    process {
        # Load the raw content from the provided path and convert it from Yaml to Json and then from Json to an Array of Custom Objects.
        $InputObject = [pscustomobject](Get-Content -Raw -Path $Path | ConvertFrom-Yaml | ConvertTo-Json | ConvertFrom-Json)
    }
    end {
        # Return the result array of custom objects.
        Return $InputObject
    }
}

function Import-ExcelData {
    <#
      .SYNOPSIS
      This function extracts all excel worksheet data and returns a hashtable of custom objects.

      .DESCRIPTION
      This function imports Microsoft Excel worksheets and puts the data in to a hashtable of pscustom objects. The hashtable
      keys are the names of the Excel worksheets with spaces omitted. The function imports data from all worksheets. It does not
      validate that the data started in cell A1 and is in format of regular rows and columns, which is required to load the data.

      .PARAMETER Path
        The optional parameter Path accepts a path string to the excel file. The string can be either the absolute or relative path.

      .PARAMETER Exclude
        The optional parameter Exclude accepts a comma separated list of strings of worksheets to exclude from loading.

      .PARAMETER HashtableReturn
        The optional switch parameter HashtableReturn directs if the return array will contain hashtables or pscustom objects.

      .PARAMETER TrimHeaders
        The optional switch parameter TrimHeaders, removes whitespace from the column headers when creating the object or hashtable.

      .EXAMPLE
        The example below shows the command line use with Parameters.

        Import-ExcelData [-Path <String>] [-Exclude <String>,<String>,...] [-HashtableReturn] [-TrimHeaders]

        PS C:\> Import-ExcelData -Path "C:\temp\myExcel.xlsx"

      or

        PS C:\> Import-ExcelData -Path "C:\temp\myExcel.xlsx" -Exclude "sheet2","sheet3"

      .NOTES

        
       
    #>

    [cmdletbinding()]
    Param (
        [Parameter(Mandatory = $false,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true)]
            [ValidateScript({Test-Path $_})]
            [String]$Path,
      [Parameter(Mandatory = $false,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNullOrEmpty()]
        [String[]]$Exclude,
      [Parameter(Mandatory = $false,
        ValueFromPipeline = $true,
        ValueFromPipelineByPropertyName = $true)]
            [Switch]$HashtableReturn = $false,
        [Parameter(Mandatory = $false,
        ValueFromPipeline = $true,
        ValueFromPipelineByPropertyName = $true)]
        [Switch]$TrimHeaders = $false
    )

    # If no path was specified, prompt for path until it has a value.
    if (-not $Path) {
        Try {
            $Path = Read-FilePath -Title "Select Microsoft Excel Workbook to Import" -Extension xls,xlsx -ErrorAction Stop
        }
        Catch {
            Return "Path not specified."
        }
    }
    # Check to see if the path is relative or absolute. A rooted path is absolute.
    if (-not [System.IO.Path]::IsPathRooted($Path)) {
      # Resolve absolute path from relative path.
      $Path = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($Path)
    }

    # Check to make sure the file is either a xls or xlsx file.
    if ((Get-ChildItem -Path $Path).Extension -notmatch "xls") {
        Return {"File is not an excel file. Please select a valid .xls or .xlsx file."}
    }

    # Create Microsoft Excel COM Object.
    $obj = Open-Excel

    # Load Microsoft Excel Workbook from location Path.
    $wb = Get-Workbook -ObjExcel $obj -Path $Path

    # Get all Excel worksheet names.
    $ws = Get-WorksheetNames -Workbook $wb

    # Declare the data array.
    $data = @()

    $ws | ForEach-Object {
      If ($HashtableReturn) {
        # Add each worksheet's hashtable objects to the data array.
        $data += Get-WorksheetData -Worksheet $(Get-Worksheet -Workbook $wb -SheetName $_) -HashtableReturn:$true -TrimHeaders:$TrimHeaders.IsPresent
      }
      else {
        # Add each worksheet's pscustom objects to the data array.
        $data += Get-WorksheetData -Worksheet $(Get-Worksheet -Workbook $wb -SheetName $_) -TrimHeaders:$TrimHeaders.IsPresent
      }
    }

    # Close Excel.
    Close-Excel -ObjExcel $obj

    # Declare an ordered hashtable.
    $ReturnSet = [Ordered]@{}

    # Add all the pscustom objects from a worksheet to the hashtable with the key equal to the worksheet name.
    # Exclude worksheets that were specified in the Exclude parameter.
    ForEach ($name in $($ws | Where-Object {$Exclude -NotContains $_})) {
      $ReturnSet[$name.replace(" ","")] = $data | Where-Object {$_.WorkSheet -eq $name}
    }

    # Return the hashtable of custom objects.
    Return $ReturnSet

}

function Read-FilePath {
    <#
      .SYNOPSIS
      This function opens a gui window dialog to navigate to an excel file.

      .DESCRIPTION
      This function opens a gui window dialog to navigate to an excel file and returns the path.

      .PARAMETER Title
        The mandatory parameter Title, is a string that appears on the navigation window.

      .PARAMETER Extension
        The optional parameter Extension, is a string array that filters the file extensions to allow selection of.

      .EXAMPLE
        The example below shows the command line use with Parameters.

        Read-FilePath -Title <String> -Extension <String[]>

        PS C:\> Read-FilePath -Title "Select a file to upload" -Extension exe,msi,intunewin

      .NOTES

    #>

    [cmdletbinding()]
    Param (
        [Parameter(Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true)]
            [String]$Title,
        [Parameter(Mandatory = $false,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true)]
            [String[]]$Extension
    )
    # https://docs.microsoft.com/en-us/previous-versions/windows/silverlight/dotnet-windows-silverlight/cc189944(v%3dvs.95)

    Add-Type -AssemblyName System.Windows.Forms
    $topform = New-Object System.Windows.Forms.Form
  $topform.Topmost = $true
    $topform.MinimizeBox = $true

    $openFileDialog = New-Object windows.forms.openfiledialog
    $openFileDialog.title = $Title
    $openFileDialog.InitialDirectory = $pwd.path
    if ($Extension) {
        $openFileDialog.filter = "File types ($(($Extension -join "; *.").Insert(0,"*.")))|$(($Extension -join ";*.").Insert(0,"*."))"
    }
    $openFileDialog.ShowHelp = $false
    $openFileDialog.ShowDialog($topform) | Out-Null

    if ($openFileDialog.FileName -eq "") {
        Return $null
    }
    else {
        Return $openFileDialog.FileName
    }
}

########################################################################################################################
function Get-UserVariables() {
    Compare-Object (Get-Variable) $AutomaticVariables -Property Name -PassThru | Where -Property Name -ne "AutomaticVariables"
}
########################################################################################################################
function Check-KeyVaultName {
    Param(
		[Parameter(Mandatory=$true)]
		[string]$keyVaultName
	)
    $firstchar = $keyVaultName[0]
    if ($firstchar -match '^[0-9]+$') {
        $keyVaultNew = Read-Host "Key Vault name can't start with numeric value. Please enter a new Key Vault Name." 
        checkKeyVaultName -keyVaultName $keyVaultNew
        return;
    }
    return $keyVaultName;
}

########################################################################################################################
function Check-AdminUserName {
    $username = Read-Host "Enter an Admin Username"
    if ($username.ToLower() -eq "admin") {
        Write-Verbose -Message "Not a valid Admin username, please select another."  
        checkAdminUserName
        return
    }
    return $username
}

########################################################################################################################
function Check-DomainName {  
    $domain = Read-Host "Domain Name"   
    if ($domain.length -gt "15") {
        Write-Verbose -Message "Domain Name is too long. Must be less than 15 characters." 
        CheckDomainName
        return
    }
    if ($domain -notmatch "^[a-zA-Z0-9.-]*$") {
        Write-Verbose -Message "Invalid character set utilized. Please verify domain name contains only alphanumeric, hyphens, and at least one period." 
        CheckDomainName
        return
    }
    if ($domain -notmatch "[.]") {
        Write-Verbose -Message "Invalid Domain Name specified. Please verify domain name contains only alphanumeric, hyphens, and at least one period."  
        CheckDomainName
        return
    }
    Return $domain
}

########################################################################################################################
function Check-Passwords {
	Param(
		[Parameter(Mandatory=$true)]
		[string]$name
	)
	$password = Read-Host -assecurestring "Enter an $($name)"
    $Ptr = [System.Runtime.InteropServices.Marshal]::SecureStringToCoTaskMemUnicode($password)
    $pw2test = [System.Runtime.InteropServices.Marshal]::PtrToStringUni($Ptr)
    [System.Runtime.InteropServices.Marshal]::ZeroFreeCoTaskMemUnicode($Ptr)
	$passLength = 14
	$isGood = 0
	if ($pw2test.Length -ge $passLength) {
		$isGood = 1
        if ($pw2test -match " ") {
          Write-Verbose -Message "Password does not meet complexity requirements. Password cannot contain spaces."
          checkPasswords -name $name
          return
        } 
        else {
          $isGood = 2
        }
        if ($pw2test -match "[^a-zA-Z0-9]") {
			    $isGood = 3
        } 
        else {
            Write-Verbose -Message "Password does not meet complexity requirements. Password must contain a special character."
            checkPasswords -name $name
            return
        }
	    if ($pw2test -match "[0-9]") {
			    $isGood = 4
        } 
        else {
            Write-Verbose -Message "Password does not meet complexity requirements. Password must contain a numerical character."
            checkPasswords -name $name
            return
        }
	    if ($pw2test -cmatch "[a-z]") {
	        $isGood = 5
        } 
        else {
            Write-Verbose -Message "Password must contain a lowercase letter."
            Write-Verbose -Message "Password does not meet complexity requirements."
            checkPasswords -name $name
            return
        }
	    if ($pw2test -cmatch "[A-Z]") {
	        $isGood = 6
        } 
        else {
            Write-Verbose -Message "Password must contain an uppercase character."
            Write-Verbose -Message "Password does not meet complexity requirements."
            checkPasswords -name $name
        }
	    if ($isGood -ge 6) {
            $passwords | Add-Member -MemberType NoteProperty -Name $name -Value $password
            return
        } 
        else {
            Write-Verbose -Message "Password does not meet complexity requirements."
            checkPasswords -name $name
            return
        }
    } 
    else {
        Write-Verbose -Message "Password is not long enough - Passwords must be at least $passLength characters long."
        checkPasswords -name $name
        return
    }
}

########################################################################################################################
Function New-AlphaNumericPassword () {
    [CmdletBinding()]
    param(
        [int]$Length = 14
    )
        $ascii=$NULL
        $AlphaNumeric = @(48..57;65..90;97..122)
        Foreach ($Alpha in $AlphaNumeric) {
            $ascii+=,[char][byte]$Alpha
            }
        for ($loop=1; $loop -le $length; $loop++) {
            $RandomPassword+=($ascii | GET-RANDOM)
        }
    return $RandomPassword
}
########################################################################################################################
function New-Cert() {
	[CmdletBinding()]
	param(
    [securestring]$certPassword,
	[string]$domain = $domainused
    )
		## This script generates a self-signed certificate
		$filePath = ".\"
		$cert = New-SelfSignedCertificate -certstorelocation cert:\localmachine\my -dnsname $domain
		$path = 'cert:\localMachine\my\' + $cert.thumbprint
		$certPath = $filePath + '\cert.pfx'
		$outFilePath = $filePath + '\cert.txt'
		Export-PfxCertificate -cert $path -FilePath $certPath -Password $certPassword
		$fileContentBytes = get-content $certPath -Encoding Byte
		[System.Convert]::ToBase64String($fileContentBytes) | Out-File $outFilePath
}
########################################################################################################################
function Write-Color([String[]]$Text, [ConsoleColor[]]$Color = "White", [int]$StartTab = 0, [int] $LinesBefore = 0, [int] $LinesAfter = 0, [string] $LogFile = "", $TimeFormat = "yyyy-MM-dd HH:mm:ss") {
  # version 0.2
  # - added logging to file
  # version 0.1
  # - first draft
  #
  # Notes:
  # - TimeFormat https://msdn.microsoft.com/en-us/library/8kb3ddd4.aspx

  $DefaultColor = $Color[0]
  if ($LinesBefore -ne 0) {  for ($i = 0; $i -lt $LinesBefore; $i++) { Write-Host "`n" -NoNewline } } # Add empty line before
  if ($StartTab -ne 0) {  for ($i = 0; $i -lt $StartTab; $i++) { Write-Host "`t" -NoNewLine } }  # Add TABS before text
  if ($Color.Count -ge $Text.Count) {
    for ($i = 0; $i -lt $Text.Length; $i++) { Write-Host $Text[$i] -ForegroundColor $Color[$i] -NoNewLine }
  }
  else {
    for ($i = 0; $i -lt $Color.Length ; $i++) { Write-Host $Text[$i] -ForegroundColor $Color[$i] -NoNewLine }
    for ($i = $Color.Length; $i -lt $Text.Length; $i++) { Write-Host $Text[$i] -ForegroundColor $DefaultColor -NoNewLine }
  }
  Write-Host
  if ($LinesAfter -ne 0) {  for ($i = 0; $i -lt $LinesAfter; $i++) { Write-Host "`n" } }  # Add empty line after
  if ($LogFile -ne "") {
    $TextToFile = ""
    for ($i = 0; $i -lt $Text.Length; $i++) {
      $TextToFile += $Text[$i]
    }
    Write-Output "[$([datetime]::Now.ToString($TimeFormat))]$TextToFile" | Out-File $LogFile -Encoding unicode -Append
  }
}
########################################################################################################################
function Get-ScriptDirectory {
  $Invocation = (Get-Variable MyInvocation -Scope 1).Value
  Split-Path $Invocation.MyCommand.Path
}
########################################################################################################################
function Login-Azure() {
  Write-Color -Text "Logging in and setting subscription..." -Color Green
  if ([string]::IsNullOrEmpty($(Get-AzContext).Account)) {
    if ($env:AZURE_TENANT) {
      Login-AzAccount -TenantId $env:AZURE_TENANT
    }
    else {
      Login-AzAccount
    }
  }
  Set-AzContext -SubscriptionId ${Subscription} | Out-null

}
########################################################################################################################
function New-ResourceGroup([string]$ResourceGroupName, [string]$Location) {
  # Required Argument $1 = RESOURCE_GROUP
  # Required Argument $2 = LOCATION

  Get-AzResourceGroup -Name $ResourceGroupName -ev notPresent -ea 0 | Out-null

  if ($notPresent) {

    Write-Host "Creating Resource Group $ResourceGroupName..." -ForegroundColor Yellow
    New-AzResourceGroup -Name $ResourceGroupName -Location $Location
  }
  else {
    Write-Color -Text "Resource Group ", "$ResourceGroupName ", "already exists." -Color Green, Red, Green
  }
}
########################################################################################################################
function Add-Secret ([string]$ResourceGroupName, [string]$SecretName, [securestring]$SecretValue) {
  # Required Argument $1 = RESOURCE_GROUP
  # Required Argument $2 = SECRET_NAME
  # Required Argument $3 = RESOURCE_VALUE

  $KeyVault = Get-AzKeyVault -ResourceGroupName $ResourceGroupName
  if (!$KeyVault) {
    Write-Error -Message "Key Vault in $ResourceGroupName not found. Please fix and continue"
    return
  }

  Write-Color -Text "Saving Secret ", "$SecretName", "..." -Color Green, Red, Green
  Set-AzureKeyVaultSecret -VaultName $KeyVault.VaultName -Name $SecretName -SecretValue $SecretValue
}
########################################################################################################################
function Get-StorageAccount([string]$ResourceGroupName) {
  # Required Argument $1 = RESOURCE_GROUP

  if ( !$ResourceGroupName) { throw "ResourceGroupName Required" }

  return (Get-AzStorageAccount -ResourceGroupName $ResourceGroupName).StorageAccountName
}
########################################################################################################################
function Get-LoadBalancer([string]$ResourceGroupName) {
  # Required Argument $1 = RESOURCE_GROUP

  if ( !$ResourceGroupName) { throw "ResourceGroupName Required" }

  return (Get-AzLoadBalancer -ResourceGroupName $ResourceGroupName).Name
}
########################################################################################################################
function Get-VirtualNetwork([string]$ResourceGroupName) {
  # Required Argument $1 = RESOURCE_GROUP

  if ( !$ResourceGroupName) { throw "ResourceGroupName Required" }

  return (Get-AzVirtualNetwork -ResourceGroupName $ResourceGroupName).Name
}
########################################################################################################################
function Get-SubNet([string]$ResourceGroupName, [string]$VNetName, [int]$Index) {
  if ( !$ResourceGroupName) { throw "ResourceGroupName Required" }
  if ( !$VNetName) { throw "VNetName Required" }

  return (Get-AzVirtualNetwork -ResourceGroupName $ResourceGroupName -Name $VNetName).Subnets[$Index].Name
}
########################################################################################################################
function Get-AutomationAccount([string]$ResourceGroupName) {
  # Required Argument $1 = RESOURCE_GROUP

  if ( !$ResourceGroupName) { throw "ResourceGroupName Required" }

  return (Get-AzAutomationAccount -ResourceGroupName $ResourceGroupName).AutomationAccountName
}
########################################################################################################################
function Get-StorageAccountKey([string]$ResourceGroupName, [string]$StorageAccountName) {
  # Required Argument $1 = RESOURCE_GROUP
  # Required Argument $2 = STORAGE_ACCOUNT

  if ( !$ResourceGroupName) { throw "ResourceGroupName Required" }
  if ( !$StorageAccountName) { throw "StorageAccountName Required" }

  return (Get-AzStorageAccountKey -ResourceGroupName $ResourceGroupName -AccountName $StorageAccountName).Value[0]
}
########################################################################################################################
function Get-KeyVault([string]$ResourceGroupName) {
  # Required Argument $1 = RESOURCE_GROUP

  if ( !$ResourceGroupName) { throw "ResourceGroupName Required" }

  return (Get-AzKeyVault -ResourceGroupName $ResourceGroupName).VaultName
}
########################################################################################################################
function New-Container ($ResourceGroupName, $ContainerName, $Access = "Off") {
  # Required Argument $1 = RESOURCE_GROUP
  # Required Argument $2 = CONTAINER_NAME

  # Get Storage Account
  $StorageAccount = Get-AzStorageAccount -ResourceGroupName $ResourceGroupName
  if (!$StorageAccount) {
    Write-Error -Message "Storage Account in $ResourceGroupName not found. Please fix and continue"
    return
  }

  $Keys = Get-AzStorageAccountKey -Name $StorageAccount.StorageAccountName -ResourceGroupName $ResourceGroupName
  $StorageContext = New-AzureStorageContext -StorageAccountName $StorageAccount.StorageAccountName -StorageAccountKey $Keys[0].Value

  $Container = Get-AzureStorageContainer -Name $ContainerName -Context $StorageContext -ErrorAction SilentlyContinue
  if (!$Container) {
    Write-Warning -Message "Storage Container $ContainerName not found. Creating the Container $ContainerName"
    New-AzureStorageContainer -Name $ContainerName -Context $StorageContext -Permission $Access
  }
}
########################################################################################################################
function Upload-File ($ResourceGroupName, $ContainerName, $FileName, $BlobName) {

  # Get Storage Account
  $StorageAccount = Get-AzStorageAccount -ResourceGroupName $ResourceGroupName
  if (!$StorageAccount) {
    Write-Error -Message "Storage Account in $ResourceGroupName not found. Please fix and continue"
    return
  }

  $Keys = Get-AzStorageAccountKey -Name $StorageAccount.StorageAccountName `
    -ResourceGroupName $ResourceGroupName

  $StorageContext = New-AzureStorageContext -StorageAccountName $StorageAccount.StorageAccountName `
    -StorageAccountKey $Keys[0].Value

  ### Upload a file to the Microsoft Azure Storage Blob Container
  Write-Output "Uploading $BlobName..."
  $UploadFile = @{
    Context   = $StorageContext;
    Container = $ContainerName;
    File      = $FileName;
    Blob      = $BlobName;
  }

  Set-AzureStorageBlobContent @UploadFile -Force;
}
########################################################################################################################
function Get-SASToken ($ResourceGroupName, $StorageAccountName, $ContainerName) {

  # Get Storage Account
  $StorageAccount = Get-AzStorageAccount -ResourceGroupName $ResourceGroupName -Name $StorageAccountName
  if (!$StorageAccount) {
    Write-Error -Message "Storage Account in $ResourceGroupName not found. Please fix and continue"
    return
  }

  $Keys = Get-AzStorageAccountKey -Name $StorageAccount.StorageAccountName `
    -ResourceGroupName $ResourceGroupName

  $StorageContext = New-AzureStorageContext -StorageAccountName $StorageAccount.StorageAccountName `
    -StorageAccountKey $Keys[0].Value

  return New-AzureStorageContainerSASToken -Name $ContainerName -Context $StorageContext -Permission rd -ExpiryTime (Get-Date).AddMinutes(20)
}
########################################################################################################################
function Import-DscConfiguration ($script, $config, $ResourceGroup, $Force) {

  $AutomationAccount = (Get-AzAutomationAccount -ResourceGroupName $ResourceGroup).AutomationAccountName

  $dscConfig = Join-Path $DscPath ($script + ".ps1")
  $dscDataConfig = Join-Path $DscPath $config

  $dscConfigFile = (Get-Item $dscConfig).FullName
  $dscConfigFileName = [io.path]::GetFileNameWithoutExtension($dscConfigFile)

  $dscDataConfigFile = (Get-Item $dscDataConfig).FullName
  $dscDataConfigFileName = [io.path]::GetFileNameWithoutExtension($dscDataConfigFile)

  $dsc = Get-AzAutomationDscConfiguration `
    -Name $dscConfigFileName `
    -ResourceGroupName $ResourceGroup `
    -AutomationAccountName $AutomationAccount `
    -erroraction 'silentlycontinue'

  if ($dsc -and !$Force) {
    Write-Output  "Configuration $dscConfig Already Exists"
  }
  else {
    Write-Output "Importing & compiling DSC configuration $dscConfigFileName"

    Import-AzAutomationDscConfiguration `
      -AutomationAccountName $AutomationAccount `
      -ResourceGroupName $ResourceGroup `
      -Published `
      -SourcePath $dscConfigFile `
      -Force

    $configContent = (Get-Content $dscDataConfigFile | Out-String)
    Invoke-Expression $configContent

    $compiledJob = Start-AzAutomationDscCompilationJob `
      -ResourceGroupName $ResourceGroup `
      -AutomationAccountName $AutomationAccount `
      -ConfigurationName $dscConfigFileName `
      -ConfigurationData $ConfigData

    while ($null -eq $compiledJob.EndTime -and $null -eq $compiledJob.Exception) {
      $compiledJob = $compiledJob | Get-AzAutomationDscCompilationJob
      Start-Sleep -Seconds 3
      Write-Output "Compiling Configuration ..."
    }

    Write-Output "Compilation Complete!"
    $compiledJob | Get-AzAutomationDscCompilationJobOutput
  }
}
########################################################################################################################
function Import-Credential ($CredentialName, $UserName, $UserPassword, $AutomationAccount, $ResourceGroup) {

  $cred = Get-AzAutomationCredential `
    -Name $CredentialName `
    -ResourceGroupName $ResourceGroup `
    -AutomationAccountName $AutomationAccount `
    -ErrorAction SilentlyContinue

  if (!$cred) {
    Set-StrictMode -off
    Write-Output "Importing $CredentialName credential for user $UserName into the Automation Account $account"

    $cred = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $UserName, $UserPassword

    New-AzAutomationCredential `
      -Name $CredentialName `
      -ResourceGroupName $ResourceGroup `
      -AutomationAccountName $AutomationAccount `
      -Value $cred

  }
}
########################################################################################################################
function Import-Variable ($name, $value, $ResourceGroup, $AutomationAccount) {
  $variable = Get-AzAutomationVariable `
    -Name $name `
    -ResourceGroupName $ResourceGroup `
    -AutomationAccountName $AutomationAccount `
    -ErrorAction SilentlyContinue

  if (!$variable) {
    Set-StrictMode -off
    Write-Output "Importing $VariableName credential into the Automation Account $account"

    New-AzAutomationVariable `
      -Name $name `
      -Value $value `
      -Encrypted $false `
      -ResourceGroupName $ResourceGroup `
      -AutomationAccountName $AutomationAccount
  }
}
########################################################################################################################
function Add-NodesViaFilter ($filter, $group, $dscAccount, $dscGroup, $dscConfig) {
  Write-Color -Text "`r`n---------------------------------------------------- "-Color Yellow
  Write-Color -Text "Register VM with name like ", "$filter ", "found in ", "$group ", "and apply config ", "$dscConfig", "..." -Color Green, Red, Green, Red, Green, Cyan, Green
  Write-Color -Text "---------------------------------------------------- "-Color Yellow

  Get-AzVM -ResourceGroupName $group | Where-Object { $_.Name -like $filter } | `
    ForEach-Object {
    $vmName = $_.Name
    $vmLocation = $_.Location
    $vmGroup = $_.ResourceGroupName

    $dscNode = Get-AzAutomationDscNode `
      -Name $vmName `
      -ResourceGroupName $dscGroup `
      -AutomationAccountName $dscAccount `
      -ErrorAction SilentlyContinue

    if ( !$dscNode ) {
      Write-Color -Text "Registering $vmName" -Color Yellow
      Start-Job -ScriptBlock { param($vmName, $vmGroup, $vmLocation, $dscAccount, $dscGroup, $dscConfig) `
          Register-AzAutomationDscNode `
          -AzContext $context `
          -AzureVMName $vmName `
          -AzureVMResourceGroup $vmGroup `
          -AzureVMLocation $vmLocation `
          -AutomationAccountName $dscAccount `
          -ResourceGroupName $dscGroup `
          -NodeConfigurationName $dscConfig `
          -RebootNodeIfNeeded $true } -ArgumentList $vmName, $vmGroup, $vmLocation, $dscAccount, $dscGroup, $dscConfig
    }
    else {
      Write-Color -Text "Skipping $vmName, as it is already registered" -Color Yellow
    }
  }
}
########################################################################################################################
function Get-ADGroup([string]$GroupName) {
  # Required Argument $1 = GROUPNAME

  if ( !$GroupName) { throw "GroupName Required" }

  $Group = Get-AzureADGroup -Filter "DisplayName eq '$GroupName'"
  if (!$Group) {
    Write-Color -Text "Creating AD Group $GroupName" -Color Yellow
    $Group = New-AzureADGroup -DisplayName $GroupName -MailEnabled $false -SecurityEnabled $true -MailNickName $GroupName
  }
  else {
    Write-Color -Text "AD Group ", "$GroupName ", "already exists." -Color Green, Red, Green
  }
  return $Group
}
########################################################################################################################
function Get-ADuser([string]$Email) {
  # Required Argument $1 = Email

  if (!$Email) { throw "Email Required" }

  $user = Get-AzureADUser -Filter "userPrincipalName eq '$Email'"
  if (!$User) {
    Write-Color -Text "Creating AD User $Email" -Color Yellow
    $PasswordProfile = New-Object -TypeName Microsoft.Open.AzureAD.Model.PasswordProfile
    $NickName = ($Email -split '@')[0]
    New-AzureADUser -DisplayName "New User" -PasswordProfile $PasswordProfile -UserPrincipalName $Email -AccountEnabled $true -MailNickName $NickName
  }
  else {
    Write-Color -Text "AD User ", "$Email", " already exists." -Color Green, Red, Green
  }

  return $User
}
########################################################################################################################
function Assign-ADGroup($Email, $Group) {

  if (!$Email) { throw "User Required" }
  if (!$Group) { throw "User Required" }

  $User = GetADUser $Email
  $Group = GetADGroup $Group
  $Groups = New-Object Microsoft.Open.AzureAD.Model.GroupIdsForMembershipCheck
  $Groups.GroupIds = $Group.ObjectId

  $IsMember = Select-AzureADGroupIdsUserIsMemberOf  -ObjectId $User.ObjectId -GroupIdsForMembershipCheck $Groups

  if (!$IsMember) {
    Write-Color -Text "Assigning $Email into ", $Group.DisplayName -Color Yellow, Yellow
    Add-AzureADGroupMember -ObjectId $Group.ObjectId -RefObjectId $User.ObjectId
  }
  else {
    Write-Color -Text "AD User ", "$Email", " already assigned to ", $Group.DisplayName -Color Green, Red, Green, Red
  }
}
########################################################################################################################
function Get-DbConnectionString($DatabaseServerName, $DatabaseName, $UserName, $Password) {
  return "Server=tcp:{0}.database.windows.net,1433;Database={1};User ID={2}@{0};Password={3};Trusted_Connection=False;Encrypt=True;Connection Timeout=30;" -f
  $DatabaseServerName, $DatabaseName, $UserName, $Password
}
########################################################################################################################
function Get-PlainText() {
  [CmdletBinding()]
  param
  (
    [parameter(Mandatory = $true)]
    [System.Security.SecureString]$SecureString
  )
  BEGIN { }
  PROCESS {
    $bstr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($SecureString);

    try {
      return [Runtime.InteropServices.Marshal]::PtrToStringBSTR($bstr);
    }
    finally {
      [Runtime.InteropServices.Marshal]::FreeBSTR($bstr);
    }
  }
  END { }
}
########################################################################################################################
function Get-VmssInstances([string]$ResourceGroupName) {
  # Required Argument $1 = RESOURCE_GROUP

  if ( !$ResourceGroupName) { throw "ResourceGroupName Required" }

  $ServerNames = @()
  $VMScaleSets = Get-AzVmss -ResourceGroupName $ResourceGroupName
  ForEach ($VMScaleSet in $VMScaleSets) {
    $VmssVMList = Get-AzVmssVM -ResourceGroupName $ResourceGroupName -VMScaleSetName $VMScaleSet.Name
    ForEach ($Vmss in $VmssVMList) {
      $Name = (Get-AzVmssVM -ResourceGroupName $ResourceGroupName -VMScaleSetName $VMScaleSet.Name -InstanceId $Vmss.InstanceId).OsProfile.ComputerName

      Write-Color -Text "Adding ", $Name, " to Instance List" -Color Yellow, Red, Yellow
      $ServerNames += (Get-AzVmssVM -ResourceGroupName $ResourceGroupName -VMScaleSetName $VMScaleSet.Name -InstanceId $Vmss.InstanceId).OsProfile.ComputerName
    }
  }
  return $ServerNames
}
########################################################################################################################
function Set-SqlClientFirewallRule($SqlServerName, $RuleName, $IP) {
  Get-AzureSqlDatabaseServerFirewallRule -ServerName $SqlServerName -RuleName $RuleName -ev notPresent -ea 0 | Out-null

  if ($notPresent) {
    Write-Host "Creating Sql Firewall Rule $RuleName..." -ForegroundColor Yellow
    New-AzureSqlDatabaseServerFirewallRule -ServerName $DbServer -RuleName $RuleName -StartIpAddress $IP -EndIpAddress $IP
  }
  else {
    Write-Color -Text "SQL Firewall Rule ", "$RuleName ", "already exists." -Color Green, Red, Green
  }
}

<#
    .SYNOPSIS
    Assign RG Policy
#>
function Set-Policy
{
  param(
    [Parameter(Mandatory=$True,Position=1)]
    [string]$subscriptionId = "",
    [Parameter(Mandatory=$True,Position=1)]
    [string]$PolicyName = "",
    [Parameter(Mandatory=$True,Position=1)]
    [string]$PolicyDescription = "",
    [Parameter(Mandatory=$True,Position=1)]
    [string]$PolicyFile = "",
    [Parameter(Mandatory=$True,Position=1)]
    [string]$PolicyResourceGroup = "",
	[Parameter(Mandatory=$True,Position=1)]
    [string]$PolicyDisplayName = "",
	[Parameter(Mandatory=$True,Position=1)]
    [string]$PolicyParameterFile = "",
	[Parameter(Mandatory=$True,Position=1)]
    [string]$PolicyScope = "",
	[Parameter(Mandatory=$True,Position=1)]
    [string]$State = ""
  )

     switch ($PolicyScope) {
      "Subscription" {
        $Scope = "/subscriptions/$subscriptionId"
		$PolicyAssignmentName = "$PolicyName-subscription"
        break
      }
      "ResourceGroup" {
        $resourceGroup  = Get-AzResourceGroup -Name $PolicyResourceGroup -ErrorAction Stop -ErrorVariable getAz.ResourceGroupFailed
		if (!$getAz.ResourceGroupFailed)
		{
			$Scope = $resourceGroup.ResourceId
			$PolicyAssignmentName = "$PolicyName-$PolicyResourceGroup"
			break
		}
			else
		{
			return "error"
			exit
		}
      }
      default { throw New-Object ArgumentException('scope') }
    }

	# First check if the policy definition already exists, this determines the cmdlet to change the policyrules
	Write-Host -ForeGroundColor Cyan "Checking if Policy Defintion already exists: $PolicyName"
	$policyDefinition = Get-AzPolicyDefinition | Where-Object {$_.Name -eq $PolicyName}

	# Now prepare the Custom Policy Definition from Template and Parameter File.
	if (!$policyDefinition)
	{
		Write-Host -ForeGroundColor Cyan "Creating new Policy Definition: $PolicyName"
		$policyDefinition = New-AzPolicyDefinition -ErrorAction Stop -ErrorVariable policyDefinitionFailed -Name $PolicyName -DisplayName $PolicyDisplayName -Description $PolicyDescription -Policy $PolicyFile -Parameter $PolicyParameterFile
	}
	else
	{
		Write-Host -ForeGroundColor Cyan "Modifying existing Policy Definition"
		$policyDefinition = Set-AzPolicyDefinition -ErrorAction Stop -ErrorVariable policyDefinitionFailed -Name $PolicyName -DisplayName $PolicyDisplayName -Description $PolicyDescription -Policy $PolicyFile -Parameter $PolicyParameterFile
	}

	# Assign Policy
	if (!$policyDefinitionFailed -and $State -eq "enabled")
	{
		$PolicyAssignmentName = "$PolicyName-$PolicyResourceGroup"
		Write-Host -ForeGroundColor Cyan "Assigning the Policy Definition: $PolicyAssignmentName"
		New-AzPolicyAssignment -Name $PolicyAssignmentName -Scope $Scope  -PolicyDefinition $policyDefinition -ErrorAction Stop -ErrorVariable policyAssignmentFailed
		if  (!$policyDefinitionFailed)
		{
			write-Host -ForeGroundColor Green "Policy Definition completed; Assigning the Policy Definition $PolicyAssignmentName completed"
			Write-Host ""
			Return $subscriptionId
		}
	}
	elseif (!$policyDefinitionFailed)
	{
		Write-Host -ForeGroundColor Green "Policy Definition completed; Assignment was skipped as state was diasabled."
		Write-Host ""
	}
	else
	{
		Write-Host -ForeGroundColor Red "Assignment was skipped as the creation of the Policy Definition has failed."
		Write-Host ""
	}
}

Function Register-AzResourceProvider1
{
  param(
    [Parameter(Mandatory=$True,Position=1)]
    [string]$subscriptionId = ""
  )
		# Register ResourceProvider NameSpace "PolicyInsights". Registering this resource provider makes sure that your subscription works with it
		Write-Host -ForeGroundColor Yellow "Registering Az.ResourceProvider for Azure Subscription Id $($subscriptionId)"
		Register-AzResourceProvider -ErrorAction Stop -ProviderNamespace Microsoft.PolicyInsights
}

Function Get-AzPolicySetDefinitionDetails
{
<#
    .SYNOPSIS
    Assign Get Policy Definitions
#>
[CmdletBinding()]
Param()
Begin{
    Try{
    $AzPolSetDef = Get-AzPolicySetDefinition
    }
    Catch
    {
        Write-error "Unable to retrieve Azure Policy Definitions"
        Throw
    }
	}

Process{
    ForEach ($PolSet in $AzPolSetDef)
    {
        Write-Verbose "Processing $($polset.displayName)"

        # Get all all PolicyDefintiions included in the PolicySet
        $includedpoldef = ($PolSet.Properties.policyDefinitions).policyDefinitionId

        $Result = @()
        ForEach ($Azpoldef in $includedpoldef)
        {
            $def = Get-AzPolicyDefinition -Id $Azpoldef

            $object = [ordered] @{
            PolicySetDefName = $PolSet.Name
            PolicySetDefID = $Polset.PolicySetDefinitionId
            PolicySetDefDisplayName = $Polset.Properties.displayName
            PolicySetDefResourceID = $polset.ResourceId
            PolicyDefID = $def.PolicyDefinitionId
            PolicyDefResourceID = $def.ResourceId
            PolicyName = $def.Name
            PolicyID = $def.PolicyDefinitionId
            PolicyDescription = $def.Properties.description
            PolicyDisplayName = $def.Properties.displayName
            PolicyCategory = $def.Properties.metadata.category
            PolicyMode = $def.Properties.mode
            PolicyParam = $def.Properties.parameters
            PolicyRuleIf = $def.Properties.policyRule.if
            PolicyRuleThen = $def.Properties.policyRule.then
            PolicyType = $def.Properties.policyType
        }
        $Result += (New-Object -TypeName PSObject -Property $object)
       }
    }
}

End{
    $Result
}
}

Function New-AADUser
{
<#
    .SYNOPSIS
        Connect to Azure Active Directory and creates a user

    .DESCRIPTION

    .Parameter UserPrincipalName
        Specifies the user ID for this user

    .Parameter Password
        Specifies the new password for the user

    .Parameter DisplayName
        Specifies the display name of the user

    .Parameter Enabled
        Specifies whether the user is able to log on using their user ID

    .Parameter FirstName
        Specifies the first name of the user

    .Parameter LastName
        Specifies the last name of the user

    .Parameter PostalCode
        Specifies the postal code of the user

    .Parameter City
        Specifies the city of the user

    .Parameter Street
        Specifies the street address of the user

    .Parameter PhoneNumber
        Specifies the phone number of the user

    .Parameter MobilePhone
        Specifies the mobile phone number of the user

    .Parameter Department
        Specifies the department of the user

    .Parameter ForceChangePasswordNextLogin
        Forces a user to change their password during their next log iny

    .Parameter ShowInAddressList
        Specifies show this user in the address list
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$UserPrincipalName,
    [Parameter(Mandatory = $true)]
    [string]$Password,
    [Parameter(Mandatory = $true)]
    [string]$DisplayName,
    [Parameter(Mandatory = $true)]
    [bool]$Enabled,
    [string]$FirstName,
    [string]$LastName,
    [string]$PostalCode,
    [string]$City,
    [string]$Street,
    [string]$PhoneNumber,
    [string]$MobilePhone,
    [string]$Department,
    [bool]$ForceChangePasswordNextLogin,
    [bool]$ShowInAddressList,
    [ValidateSet('Member','Guest')]
    [string]$UserType='Member'
)
Begin{
try{
    $PasswordProfile = New-Object -TypeName Microsoft.Open.AzureAD.Model.PasswordProfile
    $PasswordProfile.Password =$Password
    $PasswordProfile.ForceChangePasswordNextLogin =$ForceChangePasswordNextLogin
    $nick = $UserPrincipalName.Substring(0, $UserPrincipalName.IndexOf('@'))
    $Script:User = New-AzureADUser -UserPrincipalName $UserPrincipalName -DisplayName $DisplayName -AccountEnabled $Enabled -MailNickName $nick -UserType $UserType `
                    -PasswordProfile $PasswordProfile -ShowInAddressList $ShowInAddressList | Select-Object *
    if($null -ne $Script:User){
        if($PSBoundParameters.ContainsKey('FirstName') -eq $true ){
            Set-AzureADUser -ObjectId $Script:User.ObjectId -GivenName $FirstName
        }
        if($PSBoundParameters.ContainsKey('LastName') -eq $true ){
            Set-AzureADUser -ObjectId $Script:User.ObjectId -Surname $LastName
        }
        if($PSBoundParameters.ContainsKey('PostalCode') -eq $true ){
            Set-AzureADUser -ObjectId $Script:User.ObjectId -PostalCode $PostalCode
        }
        if($PSBoundParameters.ContainsKey('City') -eq $true ){
            Set-AzureADUser -ObjectId $Script:User.ObjectId -City $City
        }
        if($PSBoundParameters.ContainsKey('Street') -eq $true ){
            Set-AzureADUser -ObjectId $Script:User.ObjectId -StreetAddress $Street
        }
        if($PSBoundParameters.ContainsKey('PhoneNumber') -eq $true ){
            Set-AzureADUser -ObjectId $Script:User.ObjectId -TelephoneNumber $PhoneNumber
        }
        if($PSBoundParameters.ContainsKey('MobilePhone') -eq $true ){
            Set-AzureADUser -ObjectId $Script:User.ObjectId -Mobile $MobilePhone
        }
        if($PSBoundParameters.ContainsKey('Department') -eq $true ){
            Set-AzureADUser -ObjectId $Script:User.ObjectId -Department $Department
        }
        $Script:User = Get-AzureADUser | Where-Object {$_.UserPrincipalName -eq $UserPrincipalName} | Select-Object *
        if($SRXEnv) {
            $SRXEnv.ResultMessage = $Script:User
        }
        else{
            Write-Output $Script:User
        }
    }
    else{
        if($SRXEnv) {
            $SRXEnv.ResultMessage = "User not created"
        }
        Throw "User not created"
    }
}
finally{
}
}
}

Function Remove-AADUser
{
<#
    .SYNOPSIS
        Connect to Azure Active Directory and creates a user

    .DESCRIPTION

    .Parameter UserPrincipalName
        Specifies the user ID for this user

    .Parameter Password
        Specifies the new password for the user

    .Parameter DisplayName
        Specifies the display name of the user

    .Parameter Enabled
        Specifies whether the user is able to log on using their user ID

    .Parameter FirstName
        Specifies the first name of the user

    .Parameter LastName
        Specifies the last name of the user

    .Parameter PostalCode
        Specifies the postal code of the user

    .Parameter City
        Specifies the city of the user

    .Parameter Street
        Specifies the street address of the user

    .Parameter PhoneNumber
        Specifies the phone number of the user

    .Parameter MobilePhone
        Specifies the mobile phone number of the user

    .Parameter Department
        Specifies the department of the user

    .Parameter ForceChangePasswordNextLogin
        Forces a user to change their password during their next log iny

    .Parameter ShowInAddressList
        Specifies show this user in the address list
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$UserPrincipalName
)
Begin{
try{
    $PasswordProfile = New-Object -TypeName Microsoft.Open.AzureAD.Model.PasswordProfile
    $PasswordProfile.Password =$Password
    $PasswordProfile.ForceChangePasswordNextLogin =$ForceChangePasswordNextLogin
    $nick = $UserPrincipalName.Substring(0, $UserPrincipalName.IndexOf('@'))
    $Script:User = Remove-AzureADUser -ObjectId $UserPrincipalName
}
    Catch
    {
        Write-error "Unable to remove Azure User Account : $UserPrincipalName"
        Throw
    }
}
}

Function new-SPNApp
{
  <#
      .SYNOPSIS
        Creates a SP with Certitifcate and an Application

      .DESCRIPTION

  #>
  param
  (
    [string] $spnName,
    [string] $subscriptionName,
    [string] $applicationName,
    [string] $location,
    [String] $certPath,
    [String] $certPlainPassword,
    [string] $spnRole = "contributor",
    [switch] $grantRoleOnSubscriptionLevel = $true,
    [string] $applicationNamePrefix = "Dpi30."
  )

  #Initialize
  $displayName = [String]::Format("$applicationNamePrefix{0}", $applicationName)
  $homePage = "http://" + $displayName
  $identifierUri = $homePage

  # Initialize subscription
  $isAzureModulePresent = Get-Module -Name Az.Resources -ListAvailable
  if ([String]::IsNullOrEmpty($isAzureModulePresent) -eq $true)
  {
    Write-Output "Script requires Az modules to be present. Obtain Az from https://github.com/Azure/azure-powershell/releases. Please refer https://github.com/Microsoft/vsts-tasks/blob/master/Tasks/DeployAzureResourceGroup/README.md for recommended Az versions." -Verbose
    return
  }

  #Import Modules
  Import-Module -Name Az.Resources

  $azureSubscription = Get-AzSubscription -SubscriptionName $subscriptionName
  $tenantId = $azureSubscription.TenantId
  $id = $azureSubscription.SubscriptionId

  # Setup certificate
  $certPassword = ConvertTo-SecureString $certPlainPassword -AsPlainText -Force
  $certObject = new-object Security.Cryptography.X509Certificates.X509Certificate2
  $bytes = [convert]::FromBase64String($certPassword.SecretValueText)
  $certObject.Import($bytes, $null, [Security.Cryptography.X509Certificates.X509KeyStorageFlags]::Exportable -bor [Security.Cryptography.X509Certificates.X509KeyStorageFlags]::PersistKeySet)
  
  #$PFXCert = New-Object -TypeName System.Security.Cryptography.X509Certificates.X509Certificate2 -ArgumentList @($certPath, $certPassword)
  $PFXCert = $certObject.Export([Security.Cryptography.X509Certificates.X509ContentType]::Pkcs12, $certPassword)
  $pfxFilePath = "$certPath\$displayName.pfx"
  $keyValue = [System.Convert]::ToBase64String($PFXCert.GetRawCertData())
  $keyCredential = New-Object -TypeName Microsoft.Azure.Graph.RBAC.Version1_6.ActiveDirectory.PSADKeyCredential
  $keyCredential.StartDate =  $PFXCert.NotBefore
  $keyCredential.EndDate = $PFXCert.NotAfter
  $keyCredential.KeyId = [guid]::NewGuid()
  $keyCredential.CertValue = $keyValue

  #Check if the application already exists
  $app = Get-AzADApplication -IdentifierUri $homePage

  if (![String]::IsNullOrEmpty($app) -eq $true)
  {
    $appId = $app.ApplicationId
    Write-Output "An Azure AAD Appication with the provided values already exists, skipping the creation of the application..."
  }
  else
  {
    # Create a new AD Application, secured by a certificate
    Write-Output "Creating a new Application in AAD (App URI - $identifierUri)" -Verbose
    $azureAdApplication = New-AzADApplication -DisplayName $displayName -HomePage $homePage -IdentifierUris $identifierUri -KeyCredentials $keyCredential -Verbose
    $appId = $azureAdApplication.ApplicationId
    Write-Output "Azure AAD Application creation completed successfully (Application Id: $appId)" -Verbose
  }

  # Check if the principal already exists
  $spn = Get-AzADServicePrincipal -ServicePrincipalName $appId

  if (![String]::IsNullOrEmpty($spn) -eq $true)
  {
    Write-Output "An Azure AAD Application Principal for the application already exists, skipping the creation of the principal..."
  }
  else
  {
    # Create new SPN
    Write-Output "Creating a new SPN" -Verbose
    $spn = New-AzADServicePrincipal -ApplicationId $appId -DisplayName $spnName
    $spnName = $spn.ServicePrincipalNames
    Write-Output "SPN creation completed successfully (SPN Name: $spnName)" -Verbose

    Write-Output "Waiting for SPN creation to reflect in Directory before Role assignment"
    Start-Sleep 20
  }

  if ($grantRoleOnSubscriptionLevel)
  {
    # Assign role to SPN to the whole subscription
    Write-Output "Assigning role $spnRole to SPN App $appId for subscription $subscriptionName" -Verbose
    New-AzRoleAssignment -RoleDefinitionName $spnRole -ServicePrincipalName $appId
    Write-Output "SPN role assignment completed successfully" -Verbose
  }

  # Print the values
  Write-Output "`nCopy and Paste below values for Service Connection" -Verbose
  Write-Output "***************************************************************************"
  Write-Output "Subscription Id: $id"
  Write-Output "Subscription Name: $subscriptionName"
  Write-Output "Service Principal Client (Application) Id: $appId"
  Write-Output "Certificate password: $certPlainPassword"
  Write-Output "Certificate: $keyValue"
  Write-Output "Tenant Id: $tenantId"
  Write-Output "Service Principal Display Name: $displayName"
  Write-Output "Service Principal Names:"
  foreach ($spnname in $spn.ServicePrincipalNames)
  {
      Write-Output "   *  $spnname"
  }
  Write-Output "***************************************************************************"
}

# Export the functions above.
Export-ModuleMember -Function 'Add-*'
Export-ModuleMember -Function 'Close-*'
Export-ModuleMember -Function 'ConvertTo-*'
Export-ModuleMember -Function 'ConvertFrom-'
Export-ModuleMember -Function 'Export-*'
Export-ModuleMember -Function 'Get-*'
Export-ModuleMember -Function 'Import-*'
Export-ModuleMember -Function 'Open-*'
Export-ModuleMember -Function 'Read-*'
Export-ModuleMember -Function 'Set-*'
Export-ModuleMember -Function 'Save-*'
Export-ModuleMember -Function '*'
