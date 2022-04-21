# Prequisites
All scripts require that you can access the AWS accounts via configured SSO Profiles, which are stored in `$awsconfigPath = "~/.aws/config"`
- How to configure AWS SSO:
    - https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-sso.html 
    
    (This step will be done automatically if you execute the RDP helper in the project folder.)

All scripts require to have following tools installed on your machine:
- AWS Session Manager CLI: 
    - https://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager-working-with-install-plugin.html#install-plugin-windows



## 1. RDP Helper
**RDP SSO will not work for AD Joined Instances, there you will need to enter the password manually.**

Run RDP Helper script without parameters
- Select SSO Profile you want to connect to
- Select EC2 you want to connect to
- Script will check if there is a secret which is tagged with "Instanceid:#instanceid#" if yes
    - It reads the secret value if it matches one of the both patterns (key:value)
        1. Username: #username# , password: #password#
        2. Administrator:#password#

The script will start SSM Sessions on port 56789 - 56794, in case all ports are used the script will not establish a connection.
This can be fixed by destroying the current shell and restart it.

## 2. Bastion Host
Run the Bastion Host script without a parameter.

The script will request you to select the SSO Profile (Account) against which you want to connect.
- Select the database you want to connect to
- Select a security group which is allowed to connect against an database
- Script will spin up a stack with a bastion host, requires 5 minutes
- Script will SSM on the bastion host
- Script will print out the parameter about how to connect against the bastion host from your local
- Once you hit enter script will close the session and delete bastion host, enter "keep" to keep the bastion host running until it is manually deleted

## 3. Branch Deploy

Branch Deploy requires an S3 Bucket on your prototyping account with the pattern test-artifact-bucket-team-*, e.g. test-artifact-bucket-team-orange
Branch Deploy requires that your prototyping account is set-up as SSOProfile "prototyping"

**Run Branch Deploy without parameters**
- Script will take the local "prototyping" profile to deploy to the prototyping account
- Prototyping account must have an S3 Bucket with pattern "test-artifact-bucket-team-*"
- Infrastructure and Cross account YAML must be available in defined paths.
- Script will generate your unqiue stack-name based on the command 
    - `$stage=  (whoami) -replace '[^a-zA-Z0-9]', ''`





