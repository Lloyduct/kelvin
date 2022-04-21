## Parameter Description
The resources deployed by the infrastructure.yaml are configured by the parameters entered within the qa.conf and prod.conf.

Below is a description of all standard parameters which are available in the project template.
```json
{
  "Parameters": {
    "VpcProductVersion": "Version of the VPC Product which is deployed.",
    "Stage": "Stage of the Config File, typically prod or qa",
    "ServiceName": "Name of the service which is deployed.",
    "AlarmsEmail":"E-Mail address to be informed in case of alarms.",
    "EnableEC2Autorecover":"Boolean if you want to auto recover your Ec2 if it is stuck.",
    "EnableEnhancedMonitoring":"Boolean if you want to enable enhanced monitoring on the Ec2",
    "BackupRetentionPeriod":"Time in days to keep backups taken.",
    "EC2RestoreAMI":"AMI Id of a Snapshot from which you want to restore the Ec2",
    "EC2InstanceType":"Ec2 Intance Type",
    "OSPatchingTimeWindow": "AWS Cron Expression which defines the Operating System Maintenance Window",
    "EC2VolumeSize":"Volume size of the Ec2 instance in GB.",
    "DBSnapshotIdentifier":"Database Snapshot Id of a Snapshot from which you want to restore the RDS Server",
    "DBInstanceType":"RDS Instance Typ"
  }
}

```