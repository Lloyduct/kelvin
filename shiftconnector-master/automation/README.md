# General
All relevant cloudformation files for the CI/CD are stored in the ./automation folder. 

In the default configuration of the project template the CI/CD will deploy a 2 Stage pipeline (QA + PROD), and ensure that the pipeline is triggered whenever the master branch is pushed.

The initial configuration of the parameters and deployment of the Stacks is done by the ./scripts/script_setup/setup_cicd.ps1.

## Config Parameter 

The ./config folder stores only parameter files which are passed to the Cloudformation files.

Each configuration file has the identical name as the yaml cloudformation file to which it is passed.

## Deployment

The automation folder is deployed by the setup_cicd.ps1 script, it will deploy the files to the Automation, DEV QA and PROD account as defined in the "projectVars.json".
Whenever files in the automation folder are change you must redeploy the files against the accounts, this can be done using the setup_cicd.ps1 script.

More details about the automation script can be found in ./scripts/script_setup folder.


# Cloudformation YAML files
Following yaml files are included in the project template for the setup of the CI/CD automaton, the summary gives the high level purpose of the file. 

| File         | Deploy to  Account       | Summary  |
|:---------------:|:---------------:|:------------:|
| Core-automation-infra.yaml | Automation  | Main purpose is to have the Git2S3 product installed which pushes all code changes from the Gitlab to the Automation account. | 
| pipeline.yaml | Automation  | Main purpose is to have the Code Pipeline installed on the Automation account, which runs the build project and deploys the changes to the QA and PROD Account. | 
| buildspec.yaml | Automation  | The file is automatically deployed / referenced by the Pipeline.yaml, it includes the commands of the build. | 
| cross-account-iam-roles.yaml | QA + PROD  | Main purpose of the file is to deploy the IAM roles which deploys the Infrastructure on the QA and PROD account. | 
