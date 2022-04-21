# <ProjectName>

This repository contains all application, automation and infrastructure code of the application <ProjectName> (CAR ID <CARID>).

## AWS Accounts

| Account Name          | Account ID   | Purpose    |
|:---------------------:|:------------:|:----------:|
| <AccAutomationName> | <AccAutomationID> | Automation |
| <AccAutomationqaName> | <AccAutomationqaID> | Non-Prod   |
| <AccAutomationprodName> | <AccAutomationprodID> | Prod       |



This needs to be deployed in the automation account:
# Deployment java and Deployment Infrastructure
`aws cloudformation deploy --template-file ./automation/core-automation-infra.yaml --stack-name <AutomationInfrastructureStack> --parameter-overrides "file://<coreAutomationParameterPath>"`

Now configure Git2S3 accordingly.

# QA Cross Account Role
Afterwards changing to the non-prod (QA) account and deploying the cross account role:

`aws cloudformation deploy --template-file ./automation/cross-account-iam-roles.yaml --stack-name <qaCrossAccountRoleStack> --parameter-overrides "file://<crossAccountqaParameterPath>" --capabilities CAPABILITY_NAMED_IAM`

# PROD Cross Account Role
Afterwards changing to the prod account and deploying the cross account role:

`aws cloudformation deploy --template-file ./automation/cross-account-iam-roles.yaml --stack-name <prodCrossAccountRoleStack> --parameter-overrides "file://<crossAccountprodParameterPath>" --capabilities CAPABILITY_NAMED_IAM`

# Deployment Pipeline
Now we can deploy our pipeline (in the automation account):

`aws cloudformation deploy --template-file ./automation/pipeline.yaml --stack-name <PipelineStack> --capabilities CAPABILITY_NAMED_IAM --parameter-overrides --parameter-overrides "file://<pipelineParameterPath>"`

Finally we need to update the roles in the non-prod & prod accounts:
# Grant cross account roles access to encrypted S3 artifact bucket
QA:

`aws cloudformation deploy --template-file ./automation/cross-account-iam-roles.yaml --stack-name <qaCrossAccountRoleStack> --parameter-overrides "file://<crossAccountqaParameterPath>" --capabilities CAPABILITY_NAMED_IAM`

Prod:

`aws cloudformation deploy --template-file ./automation/cross-account-iam-roles.yaml --stack-name <prodCrossAccountRoleStack> --parameter-overrides "file://<crossAccountprodParameterPath>" --capabilities CAPABILITY_NAMED_IAM`
