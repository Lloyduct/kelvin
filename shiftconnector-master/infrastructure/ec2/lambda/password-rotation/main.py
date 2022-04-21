import boto3
import logging
import time
import os

logger = logging.getLogger()
logger.setLevel(logging.INFO)


def lambda_handler(event, context):

    arn = event['SecretId']
    token = event['ClientRequestToken']
    step = event['Step']

    secrets_client = boto3.client('secretsmanager', region_name='eu-central-1')
    ec2_client = boto3.client('ec2')

    # Find and assign instance id from secret tags
    instance = ""
    secret_tags = secrets_client.describe_secret(SecretId=arn)["Tags"]
    for tag in secret_tags:
        # Getting plato instance ID
        if tag["Key"] == "instanceid":
            instance = tag["Value"]
            break

    if step == "createSecret":
        create_secret(secrets_client, arn, token, instance)

    else:
        raise ValueError("Invalid step parameter")


def create_secret(secrets_client, arn, token, instance):
    print('--------- CREATING NEW SECRET ---------')
    ssm_client = boto3.client('ssm', region_name='eu-central-1')

    # Get previous secret value in case of errors
    previous_password = secrets_client.get_secret_value(SecretId=arn)["SecretString"].split(":")[1].replace('"','').replace('}','').strip()
 
    try:
        # Generate a random password
        print('--- Generating new password ---')
        password = secrets_client.get_random_password(PasswordLength=24, ExcludeNumbers=False, ExcludePunctuation=True, ExcludeUppercase=False, ExcludeLowercase=False, RequireEachIncludedType=True)["RandomPassword"]
        change_password = [
            "$password = '" + password + "'",
            "$computers = Hostname",
            "net.exe user Administrator $password"
        ]
        
        # Put the new password
        print('Putting new password into the secret') 
        secureString='{ \"Administrator\": \"'+ password +'\"\n }'
        secrets_client.put_secret_value(SecretId=arn,  ClientRequestToken=token, SecretString=secureString, VersionStages=['AWSCURRENT'])
        logger.info("createSecret: Successfully put secret for ARN %s and version %s." % (arn, token))

        # Sending SSM command to change password on instance
        print('Changing password on Windows instance ' + str(instance))
        response = ssm_client.send_command(InstanceIds=[instance],DocumentName='AWS-RunPowerShellScript', Parameters={ 'commands': change_password },)

        time.sleep(10)
        print('--------- NEW SECRET CREATED AND APPLIED TO INSTANCE (COMPLETED) ---------')
        return True


    except Exception as e:
        print("--------- ERROR ---------")
        print(e)

        # Restoring old password in case of error
        secureString='{ \"Administrator\": \"'+ previous_password +'\"\n }'
        secrets_client.put_secret_value(SecretId=arn,  SecretString=secureString)
        print("The previous password has been restored in secrets manager")
        return False