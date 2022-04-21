# shiftconnector

This repository contains all application, automation and infrastructure code of the application shiftconnector (CAR ID 233).

## AWS Accounts

| Account Name          | Account ID   | Purpose    |
|:---------------------:|:------------:|:----------:|
| DevOps-tauwy | 223066201812557 | Automation |
| Legacy-uaapm | 223713705977451 | Non-Prod   |
| Legacy-vqlyp | 223554250442952 | Prod       |



This needs to be deployed in the automation account:
# Deployment Git2S3 and Deployment Infrastructure
`aws cloudformation deploy --template-file ./automation/core-automation-infra.yaml --stack-name shiftconnector-core-automation --parameter-overrides "file://./automation/config/core-automation-infra.json"`

Now configure Git2S3 accordingly.

# QA Cross Account Role
Afterwards changing to the non-prod (QA) account and deploying the cross account role:

`aws cloudformation deploy --template-file ./automation/cross-account-iam-roles.yaml --stack-name shiftconnector-qa-cross-account-roles --parameter-overrides "file://./automation/config/cross-account-qa.json" --capabilities CAPABILITY_NAMED_IAM`

# PROD Cross Account Role
Afterwards changing to the prod account and deploying the cross account role:

`aws cloudformation deploy --template-file ./automation/cross-account-iam-roles.yaml --stack-name shiftconnector-prod-cross-account-roles --parameter-overrides "file://./automation/config/cross-account-prod.json" --capabilities CAPABILITY_NAMED_IAM`

# Deployment Pipeline
Now we can deploy our pipeline (in the automation account):

`aws cloudformation deploy --template-file ./automation/pipeline.yaml --stack-name shiftconnector-automation --capabilities CAPABILITY_NAMED_IAM --parameter-overrides --parameter-overrides "file://./automation/config/pipeline.json"`

Finally we need to update the roles in the non-prod & prod accounts:
# Grant cross account roles access to encrypted S3 artifact bucket
QA:

`aws cloudformation deploy --template-file ./automation/cross-account-iam-roles.yaml --stack-name shiftconnector-qa-cross-account-roles --parameter-overrides "file://./automation/config/cross-account-qa.json" --capabilities CAPABILITY_NAMED_IAM`

Prod:

`aws cloudformation deploy --template-file ./automation/cross-account-iam-roles.yaml --stack-name shiftconnector-prod-cross-account-roles --parameter-overrides "file://./automation/config/cross-account-prod.json" --capabilities CAPABILITY_NAMED_IAM`
