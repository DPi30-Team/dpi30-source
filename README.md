#Data Platform in 30 Days (DPi30) 
## Azure Data & Analytics Platform (ADAP)

[![Build Status](https://dev.azure.com/quisitive/DPi30/_apis/build/status/DPi30?branchName=master)](https://dev.azure.com/quisitive/DPi30/_build/latest?definitionId=28&branchName=master)

ARM templates, PowerShell modules and scripts, policies, alerts, rbac and other resources used in the Azure Data and Analytics Platform deployment

## ARM Templates 

The templates directory contains deployments that can be used to stand up a specific resource and can be used in the same way as nested templated. 
A master template should call each template as a separate resource passing in parameters as necessary.

A sample master template and links to individual deployment documentation can be [found here](templates/README.md).

## PowerShell Modules

The PowerShell modules directory contains helper functions used across multiple scripts.
Modules can be imported into the scripts where needed.

Module documentation can be [found here](modules/README.md).

## PowerShell Scripts

The PowerShell scripts directory contains scripts that can be used either in build and release definitions or from the command line.

## Tests

All PowerShell scripts and ARM templates should be covered by Pester tests.
These tests can be found in the tests directory. 
Tests can be either acceptance tests (filename should start with an A and tests tagged as "Acceptance")
or unit tests (filename starts with a U and tests tagged as "Unit").
Code coverage for the PowerShell scripts is also generated.

There are also some generalised quality tests (filename starts with Q and tests tagged as "Quality") in the same directory.
These tests run on all groups of files of the same type and ensure standards and quality are maintained across all files checked-in.

Additional document for creating tests and details of the quality tests can be [found here](tests/README.md).