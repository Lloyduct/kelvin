#requires -version 4
<#
.SYNOPSIS
  <Overview of script>
.DESCRIPTION
  <Brief description of script>
.PARAMETER <Parameter_Name>
  <Brief description of parameter input required. Repeat this attribute if required>
.INPUTS
  <Inputs if any, otherwise state None>
.OUTPUTS
  <Outputs if any, otherwise state None>
.NOTES
  Version:        1.0
  Author:         <Name>
  Creation Date:  <Date>
  Purpose/Change: Initial script development
.EXAMPLE
  <Example explanation goes here>
  
  <Example goes here. Repeat this attribute for more than one example>
#>

#---------------------------------------------------------[Script Parameters]------------------------------------------------------

Param (
  #Script parameters go here
)

#---------------------------------------------------------[Initialisations]--------------------------------------------------------

#Set Error Action to Silently Continue
$ErrorActionPreference = 'stop'

#Import Modules & Snap-ins

#----------------------------------------------------------[Declarations]----------------------------------------------------------

$projectVarsPath ="./scripts/script_setup/projectVars.json"
$bastionTemplatePath="./scripts/helper/bastion_host/bastion_host.yaml"
$awsconfigPath = "~/.aws/config"
$stackname = "BastionHostPS1Script"
$port = "56777"

#-----------------------------------------------------------[Functions]------------------------------------------------------------

function validate_execution_path
{
    # Ensure script is executed on project root level
    if(-not (Test-Path "./automation"))
        {
            # Check if script was executed from <root>/script_setup/
            Set-Location ..
            if(-not (Test-Path "./automation"))
        {   Set-Location ..
            if(-not (Test-Path "./automation"))
        {
            # Exit error, script cannot work without automation folder.
            Write-Output "Didn't find automation folder, please ensure script is executed on project root level-"
            break}
        }
    }
}
function select_SSOprofile {
  param (
      [Parameter()]
      [string]
      $projectVarsPath,
      [string]
      $awsconfigPath
      )
  $projectJson = Get-Content -Path $projectVarsPath -raw | ConvertFrom-Json 
  $loginlist = "[]" | ConvertFrom-Json
  $SSOList = $projectJson.DeployAccounts.AWSSSOProfile + "List All" + "Quit"
  foreach($SSOEntry in $SSOList)
  {
      $loginlist += "{`"Profile`":`"$SSOEntry`"}"|ConvertFrom-Json
  }
  $SSOprofile = ($loginlist | Out-GridView -OutputMode Single -Title "Select your profile with ENTER").Profile

  if ([string]::IsNullOrEmpty($SSOprofile) -or $SSOprofile -eq "Quit") { exit }
  if ($SSOprofile -eq "List All") {
      # Read AWS Config
      $awsConfigContent = Get-Content -Path $awsconfigPath 
      $loginlist = ($awsConfigContent | Select-String -Pattern "Profile")
      $loginlist = $loginlist -replace '\[Profile ', ''
      $loginlist = $loginlist -replace '\]', ''
      $SSOprofile = ($loginlist | ConvertFrom-CSV -Header "Profile" | Out-GridView -OutputMode Single -Title "Select your profile with ENTER").Profile
  }
  if ([string]::IsNullOrEmpty($SSOprofile)) { exit }
  return $SSOprofile 
}
function create_bastionhost {
  param (
    [Parameter()]
    [string]
    $SSOprofile
    ) 

    # Login if not authenticated
    $myProfile = aws sts get-caller-identity --output json --profile $SSOprofile | ConvertFrom-Json
    if (-Not $LASTEXITCODE -eq 0) {
        aws sso login --profile $SSOprofile
        $myProfile = aws sts get-caller-identity --output json --profile $SSOprofile | ConvertFrom-Json
    }
    $isLegacy = $myProfile.Arn -like "*COV-Legacy*"
    ## Log in to account and identify target DB
    $rdsInstancesObject = aws_cmd_get -awsCommand "rds describe-db-instances" -SSOProfile $SSOprofile
    
    $rdsInstances = $rdsInstancesObject.DBInstances | Select-Object -Property DBInstanceIdentifier,Endpoint,DBSubnetGroup,VPCSecurityGroups
    $rdsInstance = $rdsInstances | Out-GridView -OutputMode Single -Title "Select your the RDS you want to connect to."
    if ([string]::IsNullOrEmpty($rdsInstance)) {exit}
    $vpcid = $rdsInstance.DBSubnetGroup.VpcId
    $rdsSecurityGroup=$rdsInstance.VpcSecurityGroups.VpcSecurityGroupId
    $ingressSecurityGroupsObject = aws_cmd_get -awsCommand "ec2 describe-security-groups" -SSOProfile $SSOprofile
    $ingressSecurityGroups = ($ingressSecurityGroupsObject.SecurityGroups | Where-Object {$_.GroupId -eq $rdsSecurityGroup}).IpPermissions.UserIdGroupPairs.GroupId | Select-Object -Unique


    $subnetIdObject = aws_cmd_get -awsCommand "ec2 describe-subnets" -SSOProfile $SSOprofile    
    $subnetId = ($subnetIdObject.Subnets | Where-Object {$_.VpcId -eq $vpcid -and $_.Tags.value -like "*private-a"}).SubnetId
    $SecurityGroupsObject = aws_cmd_get -awsCommand "ec2 describe-security-groups" -SSOProfile $SSOprofile    
    $SecurityGroups = $SecurityGroupsObject.SecurityGroups | Where-Object {$ingressSecurityGroups -contains $_.GroupId} | Select-Object -Property GroupId,Description
    $bastionSG = $SecurityGroups | Out-GridView -OutputMode Single -Title "Select the SG for bastion Host."
    if ([string]::IsNullOrEmpty($bastionSG)) {exit}

    $BastionDBDomain=$rdsInstance.Endpoint.Address
    $DBPort=$rdsInstance.Endpoint.Port
    $BastionSecurityGroup = $bastionSG.GroupId

    $roleArnObject = aws_cmd_get -awsCommand "iam list-roles" -SSOProfile $SSOprofile  
    $roleArnObjects = ($roleArnObject.Roles | Where-Object { $_.RoleName -like "*DeployRole*"} | Select-Object -Property RoleName,Arn).Arn
    $roleArn = $roleArnObjects | Out-GridView -OutputMode Single -Title "Select the SG for bastion Host."

    ### Create bastion host
    if($isLegacy)
    {
    aws cloudformation deploy --template-file $bastionTemplatePath `
        --stack-name $stackname `
        --parameter-overrides SecurityGroup=$BastionSecurityGroup SubnetId=$subnetId DBDomain=$BastionDBDomain DBPort=$DBPort `
        --capabilities CAPABILITY_NAMED_IAM --role-arn $roleArn --profile $SSOprofile
    }else {
        aws cloudformation deploy --template-file $bastionTemplatePath `
        --stack-name $stackname `
        --parameter-overrides SecurityGroup=$BastionSecurityGroup SubnetId=$subnetId DBDomain=$BastionDBDomain DBPort=$DBPort `
        --capabilities CAPABILITY_NAMED_IAM --profile $SSOprofile
    }
    ### Get Stack Bastion Host Instance
    $bastionInstanceIdObject = aws_cmd_get -awsCommand "cloudformation describe-stack-resources" -awsParameter "--stack-name $stackname" -SSOProfile $SSOprofile
    $bastionInstanceId = ($bastionInstanceIdObject.StackResources | Where-Object {$_.ResourceType -eq "AWS::EC2::Instance" -and $_.LogicalResourceId -eq "BastionEc2Instance"}).PhysicalResourceId 

    ## Start SSM Session in Background
    # Check if target port is in use
    $portUsed = -not [string]::IsNullOrEmpty((Get-NetTCPConnection | Where-Object Localport -eq $port))
    $retryCount = 0
    while ($portUsed -and $retryCount -le 2) {
        $intPort = [int]$port
        $intPort++
        Write-Output "Port $port is in use, hence switching to $intport"
        $port = [String]$intPort
        $portUsed = -not [string]::IsNullOrEmpty((Get-NetTCPConnection | Where-Object Localport -eq $port))
        $retryCount++
        if ($retryCount -eq 2) {
            Write-Output "Exit as cannot find unused port for proxy."
            exit
        }
    }
    # Stop All Running SSM Sessions of Bastion DBs
    Get-Job -Name "ConnectBastionDB"  -ErrorAction 0 | Stop-Job
    $sb = [scriptblock]::Create("aws ssm start-session --target $bastionInstanceId --document-name AWS-StartPortForwardingSession --profile $SSOprofile --parameters 'portNumber=$DBPort,localPortNumber=$port' ")
    
    if($isLegacy)
    {
        Write-Warning "For legacy accounts you require to start the SSM session manually."
        Write-Output "################################################"
        Write-Output "################################################"
        Write-Output "##       Please open a new Powershell         ##"
        Write-Output "##       Authenticate with the Migration Role ##"
        Write-Output "Then execute following command: $sb"
        Write-Output "##       Connect to Database via:             ##"
        Write-Output "##       127.0.0.1:$port                      ##"
        Write-Output "################################################"
        Write-Output "################################################"

        Write-Warning "Please open a new Powershell console and authenticate against the account witht the MIGRATION role."
        Write-Warning "Then execute following command: $sb"
        Write-Warning "Afterwards you can connect via: 127.0.0.1:$port  "
    }else {
        
    
    # Start SSM Session
    $ssmJob = Start-Job -ScriptBlock $sb -Name "ConnectBastionDB"
    Start-Sleep 5

    ### SSM to bastion host with Portforwarding
    #aws ssm start-session --target $bastionInstanceId --document-name AWS-StartPortForwardingSession --profile $SSOprofile --parameters portNumber=$DBPort,localPortNumber=$port

    Write-Output "################################################"
    Write-Output "################################################"
    Write-Output "##       Bastion host is running              ##"
    Write-Output "##       Keep bastion run via keep            ##"
    Write-Output "##       Connect to Database via:             ##"
    Write-Output "##       127.0.0.1:$port                      ##"
    Write-Output "################################################"
    Write-Output "################################################"
    }
    ### Delete bastion host when session is closed
    $deleteMe = Read-Host    "##        Enter to terminate bastion          ##"
    if ($deleteMe -ne "keep") {
        aws cloudformation delete-stack --stack-name $stackname --profile $SSOprofile
        Write-Output "##       Bastion deleted                      ##"
        Write-Output "################################################"
        
    }else {
        Write-Output "##       Bastion will be kept                 ##"
        Write-Output "##   Please delete $stackname manually ##"
        Write-Output "################################################"
    }
    if (-not $isLegacy) {
     # Stop SSM Connection
     Write-Output     "##   Stopping SSM Connection                  ##"
     $ssmJob | Stop-Job
     Write-Output     "##   Stopped.                                 ##"
     Write-Output "################################################"       
    }

    
}

function validate_dependencies {
  $errorList = "[]" |ConvertFrom-Json
  ## Validate AWS CLI is installed 
  try {
      aws --version |Out-Null
  }
  catch {
      $errorList += "Error Please install AWS  CLI before using RDP Helper. "  
      
  }

  ## Validate Session Manager is installed
  try {
      session-manager-plugin | Out-Null 
  }
  catch {
      $errorList += "Error Please install AWS SSM CLI before using RDP Helper. https://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager-working-with-install-plugin.html#install-plugin-windows"  
      
  }
  foreach($err in $errorList)
  {
      Write-Warning $err
  }
  ## Exit if dependencies not met
  if($errorList.Length -ge 1){Exit}
}

function configure_sso()
{
    param (
        [Parameter()]
        [string]
        $projectVarsPath,
        [string]
        $awsconfigPath
        )
    # Load Json wiht project parameters
    try {
    $projectJson = Get-Content -Path $projectVarsPath -raw | ConvertFrom-Json
    # Set path of aws config and needed variables
    $region = $projectJson.Region
    # Split list of accounts

    $AccountList = $projectJson.DeployAccounts + $projectJson.AutomationAccount

    foreach($acc in $AccountList){
        
        # Set relevant account settings
        $accType = $acc.Type
        $accountId = $acc.ID
        $AWSprofile = "$($projectJson.ProjectName)-$accType"
        $accountId = $acc.ID
        $SSORole = $acc.SSORole
        $acc.AWSSSOProfile =  $AWSprofile
        create_sso_profile -awsconfigPath $awsconfigPath -accountId $accountId -SSORole $SSORole -awsRegion $region -awsProfile $AWSprofile

    ## Write profile to configuration file

    $projectJson | ConvertTo-Json | set-content $projectVarsPath
        
    }
    }
    catch {
        Write-Warning "Skipped SSO configuration since project vars does not exist in $projectVarsPath"
    }
    
}

function create_sso_profile {
    param (
        [string]
        $awsconfigPath,
        [string]
        $accountId,
        [string]
        $SSORole,
        [string]
        $awsRegion,
        [string]
        $awsProfile
    )
    # Exit if AWS config is not found
    if(-not (Test-Path "$awsconfigPath" -PathType leaf))
    {
        ## Initialize file
        $blankConfig = "[default]`nregion = eu-central-1`noutput = json "
        Add-Content -Path $awsconfigPath -Value $blankConfig
        Write-Log -message "Initialized File since it did not exist previously: $awsconfigPath" -Severity "[INFO]"
    }
    $awsConfigContent = Get-Content -Path $awsconfigPath 
    # If Account ID not empty and account is not already configured in aws config
    if(-Not ([string]::IsNullOrEmpty($accountId)) -and -not ($awsConfigContent | Where-Object {$_ -like "*$awsProfile*"})) 
    {
        # Concat AWS SSO Profile String
        $loginSkeleton = "`n[profile $awsProfile]`nsso_start_url = https://kelvin.awsapps.com/start#/`nsso_region = eu-west-1`nsso_account_id = $accountId`nsso_role_name = $SSORole`nregion = $awsRegion`noutput = json"

        # Add SSO Log-In to aws config
        Add-Content -Path $awsconfigPath -Value $loginSkeleton
        Write-Log  -message "Created AWS SSO profile $AWSprofile for Account $accountId."            
    }
}


function aws_cmd_get {
  param (
      [String]
      $awsCommand,
      [String]
      $awsParameter=$null,
      [String]
      $SSOProfile
  )

  #Write-Log -message "Retrieving values from AWS" -Severity "[DEBUG]"
  # Deploy Git2S3 Product on the automation account.
  $cmdCommand = "aws $awsCommand $awsParameter --profile $SSOProfile --output json"
  #Write-Log -message "Retrieving values from AWS: $cmdCommand" -Severity "[DEBUG]"
  $returnvalue = (Invoke-Expression $cmdCommand) | ConvertFrom-Json
  if ($LASTEXITCODE -gt 0) {
      Write-Warning "Error with Executing $cmdCommand."
      exit
  }
  return $returnvalue
}

#-----------------------------------------------------------[Execution]------------------------------------------------------------

validate_dependencies
validate_execution_path
configure_sso -projectVarsPath $projectVarsPath -awsconfigPath $awsconfigPath
$SSOprofile = select_SSOprofile -projectVarsPath $projectVarsPath -awsconfigPath $awsconfigPath 
create_bastionhost -SSOprofile $SSOprofile