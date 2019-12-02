# Tests

PowerShell scripts and ARM templates should be covered by [Pester tests](https://github.com/pester/Pester).
All the tests can be run by the `invoke-tests.ps1` script.

## Unit tests

Unit tests for granularity testing functions.
They are often used when you know what output or operation should happen for a given input(s).
PowerShell scripts are often tested using unit tests.

Unit tests should follow this naming convention `ut.filebeingtested.tests.ps1`,
where ut indicates unit test,  filebeingtested is the name of the file being tested.

## Acceptance tests

Acceptance tests the whole works as expected. 
ARM templates are often tested using acceptance tests.

Acceptance tests should follow this naming convention `at.filebeingtested.tests.ps1`.
where at indicates acceptance test,  filebeingtested is the name of the file being tested.

## Quality tests

Generalized tests that enforce a minimum level of quality around code.
They do not test functionality but rather all files have an agreed structure,
are correctly formatted (in the case of XML or JSON files),
have a minimum amount of documentation or the code follows best practice.

Quality tests should follow this naming convention `qt.typeoftest.Tests.ps1`,
where qt indicates quality test,  typeoftest is the name of the functionality being tested.

We have the following quality tests

TODO: Add Quaility Tests


### PSScripts Quality

Uses [PSScriptAnalyzer](https://github.com/PowerShell/PSScriptAnalyzer)
to ensure all PowerShell scripts in the PSScripts directory follow best practices.

