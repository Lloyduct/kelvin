# AWS Instance Scheudler

## How to use the scheduler
The AWS Instance scheduler will be deployed by the infrastructure.yaml and in the standard configuration it has the permission to start and stop Ec2 and RDS Instances.

In order to schedule an instance you will need to define first a schedule in th ./infrastucture/instance_scheduler/schedules.json . The file already contains examples, details about the schedules can be found here: https://docs.aws.amazon.com/solutions/latest/instance-scheduler/custom-resource.html

Once the schedule is deployed you can assign a Ec2 or RDS instance to a schedule by setting a tag:
- Key:      "Schedule" 
- Value:    "Name of the Schedule" 

e.g.
```yaml
    Ec2Instance:
    (...)
          Tags:
            - Key: "Schedule"
              Value: "GermanOfficeHours"
```




## Documentation about how to configure schedules:
How to use AWS Instance Scheduler?
- https://docs.aws.amazon.com/solutions/latest/instance-scheduler/solution-components.html

Configuration
Can be done in config/scheduler.conf, same will be applied for QA and PROD
- https://docs.aws.amazon.com/solutions/latest/instance-scheduler/scheduler-cli.html

Custom Resource Documentation for schedules.yaml
- https://docs.aws.amazon.com/solutions/latest/instance-scheduler/custom-resource.html

## Adjustments from Covestro
The instance scheduler is manually adjusted to solve following issue and make it deployable as nested stack:
- Issue: https://github.com/awslabs/aws-instance-scheduler/issues/214
Schedules must not be deployed as nested stack YAML due to following limitation:
- Issue: https://github.com/aws/aws-cli/issues/3991

Therefore both templates are implemented as parent stacks in the pipeline.