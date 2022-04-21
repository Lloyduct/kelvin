#!/bin/bash
set -euo pipefail # do not remove this! :) 

# this runs 2 linters against all cloud formation templates in this repo
# it's called by a few things, firstly the pipeline - automation/buildspec.yaml
# if you have the prerequisites installed, you can run this locally, else use it via the docker image - run-linters-container.sh

echo "Running linters..."

# CFN Lint  - fail fast - catch deployment failures CloudFormation won't check sufficiently before provisioning
cfn-lint infrastructure/**/*.yaml
cfn-lint --ignore-templates automation/buildspec.yaml --template automation/**/*.yaml 

# CFN Nag - scan more focussed on security
# skip the buildspec.yaml and some other non-cfn-template files
cfn_nag --version
cfn_nag_scan --input-path automation --template-pattern="^(?!.*spec).*\.yaml|..*\.yml|..*\.template"
cfn_nag_scan --input-path infrastructure --parameter-values-path=infrastructure/config/qa.conf --template-pattern="..*\.yaml|..*\.yml|..*\.template"
cfn_nag_scan --input-path infrastructure --parameter-values-path=infrastructure/config/prod.conf --template-pattern="..*\.yaml|..*\.yml|..*\.template"

echo "... done running linters"