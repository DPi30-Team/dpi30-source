#requires -Version 3.0 -Modules Pester
<#
.Synopsis
   Short description
.DESCRIPTION
   Long description
.EXAMPLE
   Example of how to use this cmdlet
.EXAMPLE
   Another example of how to use this cmdlet
.INPUTS
   Inputs to this cmdlet (if any)
.OUTPUTS
   Output from this cmdlet (if any)
.NOTES
   General notes
.COMPONENT
   The component this cmdlet belongs to
.ROLE
   The role this cmdlet belongs to
.FUNCTIONALITY
   The functionality that best describes this cmdlet
#>
function Verb-Noun
{
    [CmdletBinding(DefaultParameterSetName='Parameter Set 1', 
                  SupportsShouldProcess=$true, 
                  PositionalBinding=$false,
                  HelpUri = 'http://www.microsoft.com/',
                  ConfirmImpact='Medium')]
    [Alias()]
    [OutputType([String])]
    Param
    (
        # Param1 help description
        [Parameter(Mandatory=$true, 
                   ValueFromPipeline=$true,
                   ValueFromPipelineByPropertyName=$true, 
                   ValueFromRemainingArguments=$false, 
                   Position=0,
                   ParameterSetName='Parameter Set 1')]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [ValidateCount(0,5)]
        [ValidateSet('sun', 'moon', 'earth')]
        [Alias('p1')] 
        $Param1,

        # Param2 help description
        [Parameter(ParameterSetName='Parameter Set 1')]
        [AllowNull()]
        [AllowEmptyCollection()]
        [AllowEmptyString()]
        [ValidateScript({$true})]
        [ValidateRange(0,5)]
        [int]
        $Param2,

        # Param3 help description
        [Parameter(ParameterSetName='Another Parameter Set')]
        [ValidatePattern('[a-z]*')]
        [ValidateLength(0,15)]
        [String]
        $Param3
    )

    Begin
    {
    }
    Process
    {
        if ($pscmdlet.ShouldProcess('Target', 'Operation'))
        {
        }
    }
    End
    {
    }
}

[CmdletBinding()]
Param (
  [Parameter(Mandatory = $false)]
  [ValidateSet("All", "Acceptance", "Quality", "Unit")]
  [String] $TestType = "Acceptance",
  [Parameter(Mandatory = $false)]
  [String] $CodeCoveragePath
)

$TestParameters = @{
  OutputFormat = 'NUnitXml'
  OutputFile   = "$PSScriptRoot\TEST-$TestType.xml"
  Script       = "$PSScriptRoot"
  PassThru     = $True
}
if ($TestType -ne 'All') {
  $TestParameters['Tag'] = $TestType
}
if ($CodeCoveragePath) {
  $TestParameters['CodeCoverage'] = $CodeCoveragePath
  $TestParameters['CodeCoverageOutputFile'] = "$PSScriptRoot\CODECOVERAGE-$TestType.xml"
}
Clear-Host
Set-Location -Path $PSScriptRoot

# Remove previous runs
Remove-Item "$PSScriptRoot\TEST-*.xml"
Remove-Item "$PSScriptRoot\CODECOVERAGE-*.xml"

# Invoke tests
$Result = Invoke-Pester @TestParameters

# report failures
if ($Result.FailedCount -ne 0) { 
  Write-Error "Pester returned $($result.FailedCount) errors"
}