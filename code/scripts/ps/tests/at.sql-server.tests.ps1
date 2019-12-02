#Requires -Modules Pester
<#
.SYNOPSIS
    Tests a specific ARM template
.EXAMPLE
    Invoke-Pester 
.NOTES
    This file has been created as template for using Pester to evaluate ARM templates
#>

$templateFile = "$PSScriptRoot\..\..\..\arm\templates\sql-server.json"
$parameterTemplateFile = "$PSScriptRoot\..\..\..\arm\templates\sql-server.parameters.json"
$template = Split-Path -Leaf $templateFile

$TempTestRG = 'adap-smk-eus-rg'
$location = 'East US'

Describe "Template: $template" -Tags "Acceptance" {
     BeforeAll {
         New-AzResourceGroup -Name $TempTestRG -Location $Location -Force
     }
    
    Context "Template Syntax" {
        
        It "Has a JSON template" {        
            $templateFile | Should Exist
        }
        
		It "Has a parameters file" {        
            $parameterTemplateFile | Should Exist
        }

        It "Converts from JSON and has the expected properties" {
            $expectedProperties = ('$schema',
            'contentVersion',
            'parameters',
            'variables',
            'resources',
            'outputs') | Sort-Object
            $templateProperties = (get-content $TemplateFile | ConvertFrom-Json -ErrorAction SilentlyContinue) | Get-Member -MemberType NoteProperty | % Name
            $templateProperties | Should Be $expectedProperties
        }
    }
    
    Context "Template Validation" {

        It "Template $templateFile and $parameterTemplateFile parameter file passes validation" {
            # Complete mode - will deploy everything in the template from scratch. If the resource group already contains things (or even items that are not in the template) they will be deleted first.
            # If it passes validation no output is returned, hence we test for NullOrEmpty
            $ValidationResult = Test-AzResourceGroupDeployment -ResourceGroupName $TempTestRG -Mode Complete -TemplateFile $templateFile -TemplateParameterFile $parameterTemplateFile
            $ValidationResult | Should BeNullOrEmpty
            
        }
    }

}
