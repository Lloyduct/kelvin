# General
The folder contains all relevant templates and components to create an RDS Server with monitoring. Default configuration is set up for MS SQL.


# Cloudformation YAML files
Following yaml files are included in the project template for creating a RDS Instance.

| File         |  Summary  |
|:---------------:|:------------:|
| rds.yaml  | This file deploys the RDS instance including the required roles and options for common tasks. | 
| rds_mon.yaml | This file deploys cloudwatch monitoringfor the RDS Instance. | 


# RDS Processes
Below is the how-to documentation of common processes that are required for the RDS instances.
Examples show how to implement the changes on QA sytem.

## Restore RDS from a Snapshot
./infrastructure/config/qa.conf
- Set the "DBSnapshotIdentifier" parameter to the Snapshot ID to which you want to restore the RDS Server. Push the changes, the Cloudformation will restore the RDS to this Snapshot. This will delete and restore the entire RDS instance.
- The restore will only be done when the parameter is changed, Cloudformation will not restore automatically on future changes that don't caue a replacement.


## Change Instance Type of the RDS Instance
./infrastructure/config/qa.conf
- Set the "DBInstanceType" parameter to the RDS Instance Type which you require. Push the changes, the Cloudformation will change the Instance Type of the RDS.
