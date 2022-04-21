#requires -version 5
<#
.SYNOPSIS
    Script to connect against EC2 Instances.

.DESCRIPTION
    The script will allow to connect via RDP or SSM to an EC2 Instance. 
    In order to identify the EC2 Instance user will need to select the AWS Account, per default only accounts from current project are listed.
    With selection of "List all" the script will list all maintained SSO profiles.
    Since the script is using SSM portforwarding it will not require the instance to be in the intranet subnet or RDP ports to be opened.
    The script will automatically RDP against Windows instances and open SSM Shell for Linux instances.
    In case the password is maintained within SecretsManager the script will cache it for the log-in and sign you in.
        Secrets Manager needs to fullfill following attributes to be read automatically:
            Secret is tagged with "instanceid:<instanceid>"
            Secret Keys:
                username:<username>
                password:<password>
.PARAMETER <Parameter_Name>
    None
.INPUTS
    Requires the AWS SSO Profile and the EC2 Instance to connect against. Inputs are taken from PowerShell Grid.
.OUTPUTS
    Returns the localhost and Ports against which the SSM Session is opened.
.NOTES
    Version:        1.0
    Author:         Benedikt Pahlke
    Creation Date:  20.09.2021
    Purpose/Change: Initial script development
.EXAMPLE
    run script without passing any parameters, script should be located within the project template ./scripts/helper/*
  
#>
#---------------------------------------------------------[Initialisations]--------------------------------------------------------

#Set Error Action to Silently Continue
$ErrorActionPreference = 'stop'

#Import Modules & Snap-ins

#----------------------------------------------------------[Declarations]----------------------------------------------------------

## Script will try to establish connection on the defined local port, if it is in use the next 5 ports will be tried
$port = "56789"
$projectVarsPath = "./scripts/script_setup/projectVars.json"
$awsconfigPath = "~/.aws/config"





#-----------------------------------------------------------[Functions]------------------------------------------------------------


function validate_execution_path {
    # Ensure script is executed on project root level
    if (-not (Test-Path "./automation")) {
        # Check if script was executed from <root>/script_setup/
        Set-Location ..
        if (-not (Test-Path "./automation")) {
            Set-Location ..
            if (-not (Test-Path "./automation")) {
                # Exit error, script cannot work without automation folder.
                Write-Output "Didn't find automation folder, please ensure script is executed on project root level-"
                break
            }
        }
    }
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
function select_instance() {
    param (
        [Parameter()]
        [string]
        $SSOprofile
        )   
    # Login if not authenticated
    aws sts get-caller-identity --profile $SSOprofile | Out-Null
    if (-Not $LASTEXITCODE -eq 0) { aws sso login --profile $SSOprofile }
    ## Read all running instances from the selected account
    $ec2Response = aws_cmd_get -awsCommand "ec2 describe-instances"  -SSOProfile $SSOprofile

    $ec2Instances = ($ec2Response.Reservations | Select-Object -Property Instances).Instances
    $instanceProperties = $ec2Instances | Where-Object { $_.State.Name -like "running" } | Select-Object -Property InstanceId, State, Platform, tags, ImageId, adJoined

    foreach ($entry in $instanceProperties) {
        # Set linux OS if string is empty. (AWS Bug)
        if ([string]::IsNullOrEmpty($entry.Platform)) {
            $entry.Platform = "Other Linux"
        }

        $entry.State = $entry.State.Name
        # Skip Login if AD Joined
        if(($entry.Tags | Where-Object { $_.Key -like "cov:adsecuritygroup" }))
            {
                $entry.adJoined=$true
            }else {
                $entry.adJoined=$false
            }
        $entry.Tags = ($entry.Tags | Where-Object { $_.Key -like "name" }).value

    }
    if ([string]::IsNullOrEmpty($instanceProperties)) {
        Write-Output "No running instances found in $SSOprofile."
        exit
    }
    ## Make user select the instance to connect
    $Instanceselection = $instanceProperties | Out-GridView -OutputMode Single -Title "Select your the instance"  
    if ([string]::IsNullOrEmpty($Instanceselection)) { exit }
    return $Instanceselection
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
        Write-Warning "Error with Executing $awsCommand $awsParameter on $SSOProfile."
        exit
    }
    return $returnvalue
}
function rdp_instance {
    param (
        [Parameter()]
        [string]
        $SSOprofile,
        [PSCustomObject]
        $selectedInstance,
        [string]
        $port
        )    
    # RDP for Windows
    if ($selectedInstance.Platform -eq "windows") {
        # Get Secret
        $secret = aws_cmd_get -awsCommand "secretsmanager list-secrets" -SSOProfile $SSOprofile
        $secretArn = ($secret.SecretList | Where-Object { $_.Tags.value -contains $selectedInstance.InstanceId}).ARN
        # Check if target port is in use
        $portUsed = -not [string]::IsNullOrEmpty((Get-NetTCPConnection | Where-Object Localport -eq $port))
        $retryCount = 0
        while ($portUsed -and $retryCount -le 5) {
            $intPort = [int]$port
            $intPort++
            Write-Output "Port $port is in use, hence switching to $intport"
            $port = [String]$intPort
            $portUsed = -not [string]::IsNullOrEmpty((Get-NetTCPConnection | Where-Object Localport -eq $port))
            $retryCount++
            if ($retryCount -eq 5) {
                Write-Warning "Exit as cannot find unused port for proxy, please restart Powershell to free up Ports."
                exit
            }
        }
        # Start SSM Session
        $sb = [scriptblock]::Create("aws ssm start-session --target $($selectedInstance.InstanceId) --document-name AWS-StartPortForwardingSession --profile $SSOprofile --parameters 'portNumber=3389,localPortNumber=$port' ")
        Start-Job -ScriptBlock $sb -Name "RDPHelper,$($selectedInstance.Tags),$($selectedInstance.InstanceId),127.0.0.1,$port" | Out-Null
        Start-Sleep 5
        # SSO Against the Ec2 if secret found
        $useLogin = $true
        # Chech if secret is using pattern "username:<value>, password:<value>"
        
        if (-not [string]::IsNullOrEmpty($secretArn) -and -not $selectedInstance.adJoined -eq "True") {

            if (-not [string]::IsNullOrEmpty((((aws secretsmanager get-secret-value  --output json --secret-id $secretArn --profile $SSOprofile | ConvertFrom-Json).SecretString | ConvertFrom-Json).username))) {
                cmdkey /generic:TERMSRV/localhost /user:$(((aws secretsmanager get-secret-value --output json --secret-id $secretArn --profile $SSOprofile| ConvertFrom-Json).SecretString |ConvertFrom-Json).username) /pass:$(((aws secretsmanager get-secret-value --secret-id $secretArn --profile $SSOprofile| ConvertFrom-Json).SecretString |ConvertFrom-Json).password)
            }
            # Chech if secret is using pattern "Administrator:<password>
            elseif (-not [string]::IsNullOrEmpty((((aws secretsmanager get-secret-value  --output json --secret-id $secretArn --profile $SSOprofile | ConvertFrom-Json).SecretString | ConvertFrom-Json).Administrator))) {
                cmdkey /generic:TERMSRV/localhost /user:Administrator /pass:$(((aws secretsmanager get-secret-value --output json --secret-id $secretArn --profile $SSOprofile| ConvertFrom-Json).SecretString |ConvertFrom-Json).Administrator)
            }  
        }
        else {
            $useLogin = $false
            
        }


        $localServer = "localhost:$port"
        mstsc /v:$localServer
        
        if ($useLogin) {
            Start-Sleep 10
            cmdkey /delete:TERMSRV/localhost 
        }
        
        Write-Output "################################################"
        Write-Output "################################################"
        Write-Output "##       Established RDP                      ##"
        Write-Output "##   Below a list of all local mappings       ##"
        Write-Output "################################################"
        Write-Output "################################################"  
        $runningJobs = (get-job -Name "RDPHelper,*" -ErrorAction 0 | Where-Object { $_.State -eq "Running" }).Name | ConvertFrom-Csv -Header "Job", "Name", "Instance ID", "LocalAddress", "Port" 
        # Select-Object *,@{Name='column3';Expression={'setvalue'}} | 
        $runningJobs | Format-Table -AutoSize
    }
    # SSM for others
    else {
        Write-Output "Start SSM for non-windows GUI platform"
        aws ssm start-session --target $selectedInstance.InstanceId --profile $SSOprofile 

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
#-----------------------------------------------------------[Execution]------------------------------------------------------------

validate_dependencies
validate_execution_path
configure_sso -awsconfigPath $awsconfigPath -projectVarsPath $projectVarsPath
$SSOProfile = select_SSOprofile -awsconfigPath $awsconfigPath -projectVarsPath $projectVarsPath
$selectedInstance=select_instance -SSOprofile $SSOProfile
rdp_instance -SSOprofile $SSOProfile -selectedInstance $selectedInstance -port $port