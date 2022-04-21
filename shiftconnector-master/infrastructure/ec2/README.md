# General
The folder contains all relevant templates and components to create an Ec2 Server including Backups, Patching, Monitoring and Password Rotation. (Windows)


# Cloudformation YAML files
Following yaml files are included in the project template for creating an Ec2 Instance.

| File         |  Summary  |
|:---------------:|:------------:|
| ec2.yaml  | This file deploys the ec2 instance including the Ec2 role and the auto-recover alarms. | 
| ec2_patching.yaml | This file deploys the Systems manager patching for Windows instances. | 
| ec2_backup.yaml | This file deploys the Systems manager backup process. | 
| ec2_password-rotation.yaml | This file deploys a secret and lambda function which will set the Administrator password on ec2 Windows machines upon click on "Rotate Password" in Secrets Manager. The Lambda Function is stored in the lambda folder. | 
| ec2_mon.yaml | This file deploys the monitoring for one or several ec2 instances which are passed via parameters. | 
| ec2_mon_alarms.yaml | This file is deployed by ec2_mon.yaml and deploys the alarms for all instances passed. | 


# Ec2 Processes
Below is the how-to documentation of common processes that are required for the Ec2 instances.
Examples show how to implement the changes on QA sytem.

## Restore Ec2 from a Snapshot
./infrastructure/config/qa.conf
- Set the "EC2RestoreAMI" parameter to the AMI ID to which you want to restore the Ec2. Push the changes, the Cloudformation will restore the Ec2 to this AMI.
- The restore will only be done when the parameter is changed, Cloudformation will not restore automatically on future changes that don't caue a replacement.


## Change Instance Type of the Ec2 Instance
./infrastructure/config/qa.conf
- Set the "EC2InstanceType" parameter to the Ec2 Instance Type which you require. Push the changes, the Cloudformation will change the Instance Type of the Ec2.
