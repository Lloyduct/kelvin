# General
The infrastructure folder holds all Cloudformation Templates which are relevant and needed to deploy the application.

The CI/CD pipeline.yaml will be initially set-up to deploy the infrastructure.yaml to the QA and PRO account.

## Initial usage
Initially the infrastructure.yaml contains the nested stack resources and parameters required to deploy all templates available.

Whenever you start a new project you will need to remove all files / resources which are not used by your project.
For each resource there is also a dedicated "CloudformationDeployPolicy" that grants the CrossAccount role permissions to deploy it. 

E.g. So if you do not require Appstream following actions are needed:

1. Delete the Appstream Folder ./infrastructure/appstream 
2. Remove the Appstream Resources from the ./infrastructure.yaml
3. Delete the Resource "CloudFormationDeploymentAppStreamPolicy" in the cross-account-iam-roles.yaml which is the resource that granted the cross account role entitlement to deploy the Appstream resources.

In case you do not require any other components it will be the same process with Ec2, RDS and any other resources.

## Config Parameter 

The ./config folder stores only parameter files which are passed to the infrastructure.yaml.

Depending on the stage it takes:
- QA : qa.conf
- PROD : prod.conf
- Prototyping : proto.conf (only used by the migration teams)
