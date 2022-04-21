#requires -version 5
<#
.SYNOPSIS
  Script deloys 3 acount AWS setup with a cross account pipeline.
.DESCRIPTION
  See README.md
.PARAMETER <Parameter_Name>
  See README.md / projetVars.json
.INPUTS
  -
.OUTPUTS
  All outputs are stored to projectVars.json and README_AUTO.md 
.NOTES
  Version:        1.0
  Author:         Benedikt Pahlke
  Creation Date:  Q2 2021.
  Purpose/Change: See GIT Commits.
.EXAMPLE
  Read and follow instructions from readme.
  Call via:
      ./setup_cicd.ps1   
#>


#---------------------------------------------------------[Initialisations]--------------------------------------------------------

#Set Error Action to Silently Continue
$ErrorActionPreference = 'stop'

#Import Modules & Snap-ins

#----------------------------------------------------------[Declarations]----------------------------------------------------------


$readmeTemplatePath = "./scripts/script_setup/README_Template.md"
$readmeCreatePath = "./README_AUTO.md"
$projectVarsPath ="./scripts/script_setup/projectVars.json"
$awsconfigPath = "~/.aws/config"
#-----------------------------------------------------------[Functions]------------------------------------------------------------


function Write-Log {
    [CmdletBinding()]
    param(
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string]$Message,
 
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [ValidateSet('[INFO]','[WARNING]','[ERROR]','[DEBUG]')]
        [string]$Severity = '[INFO]'
    )
 
    
        $Time = (Get-Date -f g) 
        $Message = $Message
        $Severity = $Severity
    
    Write-Output "$Time - $Severity - $Message"
 }


function create_readme()
{   
    param (
        [Parameter()]
        [string]
        $readmeTemplatePath,
        [string]
        $readmeCreatePath,
        [string]
        $projectVarsPath
        )
    ### Get Readme Template
    $readme = Get-Content -Path $readmeTemplatePath

    # Load Json wiht project parameters
    $projectJson = Get-Content -Path $projectVarsPath -raw -ErrorAction Stop | ConvertFrom-Json

    # Replace Parameters in Readme

    $readme = $readme.replace("<ProjectName>",$projectJson.ProjectName)
    $readme = $readme.replace("<AccAutomationName>",$projectJson.AutomationAccount.Name)
    $readme = $readme.replace("<AccAutomationID>",$projectJson.AutomationAccount.ID)
    $readme = $readme.replace("<CARID>",$projectJson.CARID)
    $readme = $readme.replace("<AutomationInfrastructureStack>",$projectJson.GeneratedValues.AutomationInfrastructureStack)
    # Iterate and replace values for all deploy accounts
    foreach($account in $projectJson.DeployAccounts)
    {
        $readme = $readme.replace("<$($account.Type)CrossAccountRoleStack>",$account.CrossAccountRoleStack)
        $readme = $readme.replace("<AccAutomation$($account.Type)Name>",$account.Name)
        $readme = $readme.replace("<AccAutomation$($account.Type)ID>",$account.ID)
        $readme = $readme.replace("<crossAccount$($account.Type)ParameterPath>",$account.configCrossAccount)
        $readme = $readme.replace("<crossAccount$($account.Type)ParameterPath>",$account.CrossAccountRoleStack)
    }

    $readme = $readme.replace("<PipelineStack>",$projectJson.GeneratedValues.PipelineStack)
    $readme = $readme.replace("<coreAutomationParameterPath>",$projectJson.automationConfigcoreAutomationInfra)
    $readme = $readme.replace("<pipelineParameterPath>",$projectJson.automationConfigpipeline)
    $readme = $readme.replace("<GITVersion>",$projectJson.GitVersion)
    $readme | Set-Content -Path $readmeCreatePath
    Write-Log  -message "Created $readmeCreatePath file"
}

function validateVars()
{
    param (
        [Parameter()]
        [string]
        $projectVarsPath
        )
    Write-Log -message "Validating projectVars.json inputs."
    $projectJson = Get-Content -Path $projectVarsPath -raw -ErrorAction Stop | ConvertFrom-Json
    $errorMessage = ""
    try {
        aws --version |Out-Null
    }
    catch {
        $errorMessage = -join ($errorMessage,"`n","AWS CLI IS NOT INSTALLED.")
    }

    
    # Verify Variables do only contain alphanumeric,- and _
    if((-Not ($projectJson.ProjectName -match "^[a-zA-Z0-9-_]+$"))){$errorMessage = -join ($errorMessage,"`n","ProjectName must only contain alphanumeric, low line and dash.")}
    if((-Not ($projectJson.Region -match "(?:[\s]|^)(eu-central-1|us-east-1|ap-southeast-1)(?=[\s]|$)"))){$errorMessage = -join ($errorMessage,"`n","Region must be eu-central-1, eu-west-1, us-east-1 or ap-southeast-1.")}
    if((-Not ($projectJson.AccountType -match "(?:[\s]|^)(devops|legacy)(?=[\s]|$)"))){$errorMessage = -join ($errorMessage,"`n","AccountType must be devops or legacy.")} 
    #if((-Not ($projectJson.RepositoryPath -match "^[a-zA-Z0-9-_]+\/+.+\.zip"))){$errorMessage = -join ($errorMessage,"`n","Path must be matching Pattern ^[a-zA-Z0-9-_]+\/+.+\.zip, e.g. aws-migration-team/project-template/master/aws-migration-team_project-template.zip")}
    if((-Not ($projectJson.AutomationAccount.ID -match "^$|^\d+$"))){$errorMessage = -join ($errorMessage,"`n","Automation Accound ID must be only digits")}
    
    foreach($account in $projectJson.DeployAccounts)
    {
        if((-Not ($account.ID -match "^$|^\d+$"))){$errorMessage = -join ($errorMessage,"`n","$($account.Type) Accound ID must be only digits or empty - no spaces")}
    }
    
    
    # Throw error, stop script in case inputs are not valid.
    if(-Not [string]::IsNullOrEmpty($errorMessage))
    {   Write-Warning "$errorMessage"
        Write-Output "Exit script due to failed dependencies."
        Exit }
        Write-Log -message "Finished validation."
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
    }
    catch {
        Write-Warning "Failed SSO configuration since project vars does not exist in $projectVarsPath"
        exit
    }
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
        $loginSkeleton = "`n[profile $awsProfile]`nsso_start_url = https://covestro.awsapps.com/start#/`nsso_region = eu-west-1`nsso_account_id = $accountId`nsso_role_name = $SSORole`nregion = $awsRegion`noutput = json"

        # Add SSO Log-In to aws config
        Add-Content -Path $awsconfigPath -Value $loginSkeleton
        Write-Log  -message "Created AWS SSO profile $AWSprofile for Account $accountId."            
    }
}

function generate_config_files()
{

    param (
        [Parameter()]
        [string]
        $projectVarsPath
    )
    # load projectVars
    $projectJson = Get-Content -Path $projectVarsPath -raw | ConvertFrom-Json
    # load config files
    $automationConfigcoreAutomationInfra = Get-Content -Path $projectJson.automationConfigcoreAutomationInfra -raw | ConvertFrom-Json
    $automationConfigpipeline = Get-Content -Path $projectJson.automationConfigpipeline -raw | ConvertFrom-Json
    # Load variables
    $projectName = $projectJson.ProjectName
    $region = $projectJson.Region

    $automationStack = -join($projectName,$projectJson.CoreAutomationInfrastructureStackSuffix)
    $pipelineStack = -join($projectName,$projectJson.PipelineStackSuffix)
    $CloudFormationDeploymentRoleName = -join($projectName,"-deployrole")

    # Assemble repository ObjectKey
    $RepositorySSHorHTMLPath = $projectJson.RepositorySSHorHTML

    if ($RepositorySSHorHTMLPath -like "https://gitlab.covestro.com*") {
        $RepositoryPath = $RepositorySSHorHTMLPath.replace("https://gitlab.covestro.com/","")
    }elseif ($RepositorySSHorHTMLPath -like "git@gitlab.ssh*") {
        $RepositoryPath = $RepositorySSHorHTMLPath.split(":")[1]
    }else {
        Write-Warning "Could not parse $RepositorySSHorHTMLPath to the S3 Source object key."
        Exit
    }
    # Remove .git ending
    $RepositoryPath = $RepositoryPath.Remove($RepositoryPath.length-4)
    $projectJson.GeneratedValues.GitlabUrl = "https://gitlab.covestro.com/"+ $RepositoryPath
    $RepositoryPathSuffix = $RepositoryPath.Replace("/","_")
    $RepositoryPath = $RepositoryPath +"/master/"+$RepositoryPathSuffix + ".zip"

    $projectJson.GeneratedValues.RepositoryObjectKey = $RepositoryPath

    # Write generated values to projectJson
    $projectJson.GeneratedValues.AutomationInfrastructureStack=$automationStack
    $projectJson.GeneratedValues.PipelineStack=$pipelineStack

    # Set VPC For account type
    if ($projectJson.AccountType -eq "devops") {
        $LZPortfolioID = $projectJson.LZPortfolioIDDevOps.$region
    }elseif ($projectJson.AccountType -eq "legacy") {
            $LZPortfolioID = $projectJson.LZPortfolioIDLegacy.$region
    }

    # Set SES Portfolio
    $SESPortfolioID = $projectJson.SESPortfolioID.$region

    # Configure Deployment Account configuration
    foreach($account in $projectJson.DeployAccounts)
    {
        $account.CrossAccountRoleStack = -join($projectName,"-",$account.Type,$projectJson.CrossAccountRoleStackSuffix)
        $automationConfigcrossAccount = Get-Content -Path $account.configCrossAccount -raw | ConvertFrom-Json
        # Set variables for cross account dev
        $automationConfigcrossAccount.Parameters.HostAccountId = $projectJson.AutomationAccount.ID
        $automationConfigcrossAccount.Parameters.LZPortfolioID = $LZPortfolioID
        $automationConfigcrossAccount.Parameters.SESPortfolioID = $SESPortfolioID
        $automationConfigcrossAccount.Parameters.CloudFormationDeploymentRoleName =$CloudFormationDeploymentRoleName 
        #Write to file
        $automationConfigcrossAccount | ConvertTo-Json | set-content $account.configCrossAccount  

        switch ($account.Type) {
            "qa" {$automationConfigpipeline.Parameters.NonProdAccountId = $account.ID  }
            "prod" {$automationConfigpipeline.Parameters.ProdAccountId = $account.ID   }
            Default {
                Write-Warning "Unknown Account type $($account.Type)."
                Exit
            }
        }
        
        
    }


    $AutomationSSORole=$projectJson.AutomationAccount.SSORole
    $CEPPortfolioID = $projectJson.CEPPortfolioID.$region
    $Git2S3ProvisionedProductName = -join($projectJson.Git2S3ProvisionedProductNamePrefix, $projectName) 
    $Git2S3BucketName = (-join($projectName,$projectJson.Git2S3BuckettNameSuffix)).ToLower()



    $automationProfile = $projectJson.AutomationAccount.AWSSSOProfile
    # Get AWSSSOAccessRoleARN 
    $iamRoles =aws iam list-roles --profile $automationProfile --output json| ConvertFrom-Json
    $AWSSSOAccessRoleARN =  ($iamRoles.Roles | Where-Object {$_.RoleName -like "AWSReservedSSO_$($AutomationSSORole)_*"}).Arn 

# Set variables for core automation infra
    $automationConfigcoreAutomationInfra.Parameters.Git2S3Version = $projectJson.GitVersion
    $automationConfigcoreAutomationInfra.Parameters.Git2S3IntegrationApiKeyArn = $projectJson.GitIntegrationApiKeyArn
    $automationConfigcoreAutomationInfra.Parameters.Git2S3OutputBucketName =  $Git2S3BucketName
    $automationConfigcoreAutomationInfra.Parameters.Git2S3ProvisionedProductName = $Git2S3ProvisionedProductName
    $automationConfigcoreAutomationInfra.Parameters.CEPPortfolioID = $CEPPortfolioID
    $automationConfigcoreAutomationInfra.Parameters.SSORole = $AWSSSOAccessRoleARN
    $automationConfigcoreAutomationInfra.Parameters.AccountType = $projectJson.AccountType
    $automationConfigcoreAutomationInfra.Parameters.ServiceName = $projectName
    # Write to file
    $automationConfigcoreAutomationInfra | ConvertTo-Json | set-content $projectJson.automationConfigcoreAutomationInfra

# Set variables for pipeline
    $automationConfigpipeline.Parameters.Git2S3BucketName = $Git2S3BucketName
    $automationConfigpipeline.Parameters.SourceObjectKey =  $projectJson.GeneratedValues.RepositoryObjectKey
    $automationConfigpipeline.Parameters.ApplicationName = $projectName
    $automationConfigpipeline.Parameters.AccountType = $projectJson.AccountType
    # Add Git2S3SnsImportValue
    $automationConfigpipeline.Parameters.GitLabTargetAddressExportValue = "$automationStack-Git2S3SnsArn"
    $automationConfigpipeline.Parameters.CloudFormationDeploymentRoleName =$CloudFormationDeploymentRoleName 
    #Write to file
    $automationConfigpipeline | ConvertTo-Json | set-content $projectJson.automationConfigpipeline

    $projectJson | ConvertTo-Json | set-content $projectVarsPath
    Write-Log "Updated Configuration Files based on $projectVarsPath Input."
}

function login_sso_aws {
    param (
        [Parameter()]
        [string]
        $projectVarsPath
    )
    # Load Json wiht project parameters
    $projectJson = Get-Content -Path $projectVarsPath -raw -ErrorAction Stop | ConvertFrom-Json
    $SSOProfile = $projectJson.AutomationAccount.AWSSSOProfile

    aws sts get-caller-identity --profile $SSOProfile | Out-Null
    # Automation
    if (-Not $LASTEXITCODE -eq 0) {
        Write-Log "AWS login expired, trigger aws SSO login."
        aws sso login --profile $SSOProfile | Out-Null
    }
}

function deploy_cicd()
{   
    param (
        [Parameter()]
        [string]
        $projectVarsPath
    )       
    # load JSON
    $projectJson = Get-Content -Path $projectVarsPath -raw | ConvertFrom-Json
    
    
    # AWS SSO Profiles
    $automationProfile = $projectJson.AutomationAccount.AWSSSOProfile

    # General Variables
    $automationStack = $projectJson.GeneratedValues.AutomationInfrastructureStack
    $pipelineStack = $projectJson.GeneratedValues.PipelineStack

    #YAML Files to deploy
    $CoreAutomationYAML = $projectJson.coreAutomationInfraPath
    $CrossAccountRolesYAML = $projectJson.CrossAccountRolesYAML
    $automationYAML = $projectJson.automationYAML

    # Load config Paths
    $coreAutomationParameterPath = $projectJson.automationConfigcoreAutomationInfra
    $pipelineParameterPath = $projectJson.automationConfigpipeline

    # Load Configs
    $coreAutomationConfig = Get-Content -Path $coreAutomationParameterPath -raw | ConvertFrom-Json
    $Git2S3ProvisionedProductName = $coreAutomationConfig.Parameters.Git2S3ProvisionedProductName  
    $automationConfigpipeline = Get-Content -Path $pipelineParameterPath -raw | ConvertFrom-Json

    foreach($account in $projectJson.DeployAccounts){
    # Set HostedZoneIds
    if ([string]::IsNullOrEmpty($account.HostedZoneId)) {
        $HostedZoneIDsJson= aws_cmd_get -awsCommand "route53 list-hosted-zones" -SSOProfile $account.AWSSSOProfile
        try {
            $HostedZoneID = ($HostedZoneIDsJson.HostedZones | Where-Object{$_.Name -eq "$($account.ID).aws.glpoly.net."}).Id.replace("/hostedzone/","")
            aws ssm put-parameter --name "HostedZoneId"  --type "String" --value "$HostedZoneID" --overwrite --profile $account.AWSSSOProfile  | Out-Null  
            $account.HostedZoneId = $HostedZoneID
            if ($LASTEXITCODE -eq 0) {
                Write-Log -message "Set HostedZoneID on $($account.ID) Account as SSM Parameter HostedZoneId"
            }else {
                Write-Warning "Error with creating hosted zone. For legacy it is not supported."
            }
            
        }
        catch {
            Write-Warning "Failed to set HostedZone for $account."
            Write-Warning  "Message: $_"
            exit
        }
    }
    }    
    # Activate stop on error
    Set-StrictMode -Version Latest
    $ErrorActionPreference = "Stop"
    $PSDefaultParameterValues['*:ErrorAction']='Stop'

    # Get / Set Git2S3 Secret
    if ([string]::IsNullOrEmpty($projectJson.GitIntegrationApiKeyArn)) {
        Write-Warning "No Git2S3 Password ARN entered, please create a password via $($projectJson.GeneratedValues.GitlabUrl)/-/settings/access_tokens"
        $secret = Read-Host "Please Enter the Password for Git2S3" 

        $secretString = '"{""GitIntegrationApiKey"":""#secret""}"'.Replace("#secret",$secret)
        try {
            $secretArn=aws secretsmanager create-secret --name "$($projectJson.ProjectName)-Git2S3Secret" --description "Automatically created by setup_cicd.ps1 deployment" --secret-string $secretString --profile $automationProfile --output json
            $projectJson.GitIntegrationApiKeyArn = ($secretArn | ConvertFrom-Json).ARN
            $projectJson | ConvertTo-Json | set-content $projectVarsPath
            
            # Update ARN in ConfigCoreAutomationInfra
            $automationConfigcoreAutomationInfra = Get-Content -Path $projectJson.automationConfigcoreAutomationInfra -raw | ConvertFrom-Json
            $automationConfigcoreAutomationInfra.Parameters.Git2S3IntegrationApiKeyArn = $projectJson.GitIntegrationApiKeyArn
            $automationConfigcoreAutomationInfra | ConvertTo-Json | set-content $projectJson.automationConfigcoreAutomationInfra
        }
        catch {
            Write-Warning "Failed to create Secret."
            Exit
        }

        
    }


    # Deploy Core Automation YAML
    cfn_deploy -templateFilePath $CoreAutomationYAML -stackName $automationStack -paramFile $coreAutomationParameterPath -SSOProfile $automationProfile

    $returnObject = aws_cmd_get -awsCommand "servicecatalog get-provisioned-product-outputs" -awsParameter "--provisioned-product-name $Git2S3ProvisionedProductName" -SSOProfile $automationProfile

    # Read Outputs from Git2S3
    foreach ($key in "OutputBucketName","PublicSSHKey", "GitPullWebHookApi")
    {
        try {            
            $projectJson.GIT.$key = ($returnObject.Outputs | Where-Object {$_.OutputKey -eq $key}).OutputValue
        }
        catch {
            Write-Warning "Error when trying to read $key from Git2S3 Stack Output: $Git2S3ProvisionedProductName"
            exit
        }
        
    }

    # Write Changes to file
    $projectJson | ConvertTo-Json | set-content $projectVarsPath

    ## Deploy QA and PROD Cross Account Roles if ARN values are Empty (to cover initial run)
    foreach($account in $projectJson.DeployAccounts)
    {
        # Deploy only if initial run (ArtifactBucketARN is empty)
        $crossAccountConfig = Get-Content -Path $account.configCrossAccount -raw | ConvertFrom-Json
        if ([string]::IsNullOrEmpty($crossAccountConfig.Parameters.ArtifactBucketArn)) {
            cfn_deploy -templateFilePath $CrossAccountRolesYAML -stackName $account.CrossAccountRoleStack -paramFile $account.configCrossAccount -SSOProfile $account.AWSSSOProfile
            $iamRoleJson = aws_cmd_get -awsCommand "iam get-role" -awsParameter "--role-name CodePipelineCrossAccountRole-$($account.type)" -SSOProfile $account.AWSSSOProfile
            try{ $iamRoleArn = $iamRoleJson.Role.Arn}
            catch{
                Write-Warning "Failed to parse iamRoleArn for $account"
                Exit
            }
            switch ($account.Type) {
                "qa" {  
                    $automationConfigpipeline.Parameters.CodePipelineNonProdCrossAccountRoleArn = $iamRoleArn
                }
                "prod"{
                    $automationConfigpipeline.Parameters.CodePipelineProdCrossAccountRoleArn = $iamRoleArn
                }
                Default {
                    Write-Warning "Error unknown Account Type $($account.Type)."
                    Exit
                }
            }
        }
    }
    # Write changes to pipeline config parameter file
    $automationConfigpipeline | ConvertTo-Json | set-content $pipelineParameterPath

    # Deploy Pipeline
    cfn_deploy -templateFilePath $automationYAML -stackName $pipelineStack -paramFile $pipelineParameterPath -SSOProfile $automationProfile
    # Get $ArtifactBucketARN , Get $ArtifactBucketKey, set in QA / PROD Parameters

    $automationExportValues = aws_cmd_get -awsCommand "cloudformation list-exports" -SSOProfile $automationProfile
    $ArtifactBucketARN = ($automationExportValues.Exports | Where-Object {$_.Name -eq "$pipelineStack-ArtifactBucketArn"}).Value
    $ArtifactBucketKey =($automationExportValues.Exports | Where-Object {$_.Name -eq "$pipelineStack-ArtifactBucketEncryptionKey"}).Value
    
    # Add to Cross Account Config and Deploy CrossAccountRole
    foreach($account in $projectJson.DeployAccounts)
    {
        $crossAccountConfig = Get-Content -Path $account.configCrossAccount -raw | ConvertFrom-Json
        $crossAccountConfig.Parameters.ArtifactBucketArn = $ArtifactBucketARN
        $crossAccountConfig.Parameters.ArtifactKey = $ArtifactBucketKey
        $crossAccountConfig | ConvertTo-Json | Set-Content  $account.configCrossAccount
        cfn_deploy -templateFilePath $CrossAccountRolesYAML -stackName $account.CrossAccountRoleStack -paramFile $account.configCrossAccount -SSOProfile $account.AWSSSOProfile
    }
}

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
            exit}
        }
    }
}

function cfn_deploy {
    param (
        [String]
        $stackName,
        [String]
        $templateFilePath,
        [String]
        $SSOProfile,
        [String]
        $paramFile
    )
    Write-Log -message "Deploying $templateFilePath as Stack $stackName on $SSOProfile with $paramFile"
    # Deploy Git2S3 Product on the automation account.
    aws cloudformation deploy --template-file $templateFilePath --stack-name $stackName  `
    --parameter-overrides "file://$paramFile" `
    --capabilities CAPABILITY_NAMED_IAM `
    --profile $SSOProfile | Out-Null
    if ($LASTEXITCODE -gt 0) {
        Write-Warning "Error with deploying $templateFilePath"
        exit
    }else {
        Write-Log -Message "Updated $stackName complete."
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
        Write-Warning "Error with Executing $awsCommand $awsParameter on $SSOProfile."
        exit
    }
    return $returnvalue
}

#-----------------------------------------------------------[Execution]------------------------------------------------------------
 
# Validate execution path
validate_execution_path

# # Validate inputs
validateVars -projectVarsPath $projectVarsPath

# # Configure SSO 
configure_sso -projectVarsPath $projectVarsPath -awsconfigPath $awsconfigPath
# # Log-In to AWS
login_sso_aws -projectVarsPath $projectVarsPath
# # Generate config file values
generate_config_files -projectVarsPath $projectVarsPath
# # Deploy CICD
deploy_cicd -projectVarsPath $projectVarsPath

# # # Create readme with projectVars
create_readme -readmeTemplatePath $readmeTemplatePath -readmeCreatePath $readmeCreatePath -projectVarsPath $projectVarsPath
