<#
    .SYNOPSIS
      This script opens the CMDB spreadsheet and creates ARM Parameter files for each worksheet that begins with "Az-"

    .PARAM
        $adapCMDB - Excel Spreadsheet CMDB

    .PARAMETER paramDirectory 
      Template Parameter file folder location where .json files will be created

    .EXAMPLE
    .\create-arm-template-parameter-files.ps1  -$adapCMDB adap-cmdb.xlsx
#>
param(
    [string]$adapCMDB                     = $adapCMDB,
    [Parameter(Mandatory=$true,HelpMessage='Root Directory where Blueprint files are located')]
    [string] $paramDirectory
)

 function ConvertFrom-ExcelToJson {
     <#
      .SYNOPSIS
        Reads data from a sheet, and for each row, calls a custom scriptblock with a list of property names and the row of data.
        This is added to a PSCustomObject

      .EXAMPLE
        $paramFiles = ConvertFrom-ExcelToJson -WorkSheetname $worksheetName -Path $adapCMDB 
    #>
    [CmdletBinding()]
    param(
        [Alias("FullName")]
        [Parameter(ValueFromPipelineByPropertyName = $true, ValueFromPipeline = $true, Mandatory = $true)]
        [ValidateScript( { Test-Path $_ -PathType Leaf })]
        $Path,
        [Alias("Sheet")]
        $WorkSheetname = 1,
        [Alias('HeaderRow', 'TopRow')]
        [ValidateRange(1, 9999)]
        [Int]$StartRow,
        [string[]]$Header,
        [switch]$NoHeader
        
    )
    $params = @{} + $PSBoundParameters
    ConvertFrom-ExcelData @params {
        param($propertyNames, $record)
    
      $ParametersFile = [PSCustomObject]@{
        "`$schema"     = "http://schema.management.azure.com/schemas/2015-01-01/deploymentParameters.json#"
        contentVersion = "1.0.0.0"
        parameters     = @{ }
      }
      foreach ($pn in $propertyNames) {
        $ParametersFile.parameters.Add($pn, @{ value = $record.$pn })
      }
      #Return the paramater files for export to json file
      $ParametersFile
      return $ParametersFile
    }
} 

$paramFiles = 
$cmdbExcel = Open-Excel
$wb = Get-Workbook -ObjExcel $cmdbExcel -Path $adapCMDB
$worksheets = Get-WorksheetNames -Workbook $wb
Close-Excel -ObjExcel $cmdbExcel
for ($w=0; $w -lt $worksheets.length; $w++) {
  if ($worksheets[$w].StartsWith("Az-")) {
    [string]$worksheetName = $worksheets[$w]
    #$e = Open-ExcelPackage $adapCMDB
    $paramFiles = ConvertFrom-ExcelToJson -WorkSheetname $worksheetName -Path $adapCMDB 
    Write-Verbose -Message ("Creating $paramFiles.length parameter files." ) -Verbose
    $par=0
    foreach($file in $paramFiles){
        if ($par%2 -eq 0) {
          $jsonFile = $worksheetName.Remove(0,3)
          $TemplateParametersFilePath = "$paramDirectory\$jsonFile.$par.parameter.json"
          Set-Content -Path $TemplateParametersFilePath -Value ([Regex]::Unescape(($paramFiles[$par] | ConvertTo-Json -Depth 10))) -Force
          }
          $par++
        }
     #Close-ExcelPackage -NoSave $e
     $paramFiles = $null
     $par = $null
  }
}