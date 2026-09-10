$ErrorActionPreference = "Stop"

$ProjectRoot   = Split-Path -Parent $PSScriptRoot
$TerraformDir = Join-Path $ProjectRoot "terraform"
$Credentials  = Join-Path $ProjectRoot "playground-credentials.json"
$Profile      = "kodekloud"

function Wait-WinRM {
    param (
        [Parameter(Mandatory = $true)]
        [string]$IpAddress
    )

    Write-Host "Waiting for WinRM on $IpAddress..."

    for ($i = 1; $i -le 30; $i++) {
        $result = Test-NetConnection `
            -ComputerName $IpAddress `
            -Port 5986 `
            -WarningAction SilentlyContinue

        if ($result.TcpTestSucceeded) {
            Write-Host "WinRM is available on $IpAddress"
            return
        }

        Start-Sleep -Seconds 10
    }

    throw "WinRM is not available on $IpAddress."
}

if (-not (Test-Path $Credentials)) {
    throw "Fichier introuvable : $Credentials"
}

Write-Host "Loading KodeKloud credentials..."

$creds = Get-Content $Credentials -Raw | ConvertFrom-Json

if (-not $creds.AccessKeyId -or -not $creds.SecretAccessKey) {
    throw "AccessKeyId ou SecretAccessKey absent du fichier JSON."
}

aws configure set aws_access_key_id $creds.AccessKeyId --profile $Profile
aws configure set aws_secret_access_key $creds.SecretAccessKey --profile $Profile
aws configure set region us-east-1 --profile $Profile
aws configure set output json --profile $Profile

Write-Host "Checking AWS credentials..."

aws sts get-caller-identity --profile $Profile

if ($LASTEXITCODE -ne 0) {
    throw "Les credentials AWS ne sont pas valides."
}

Write-Host "Initializing Terraform..."

terraform -chdir=$TerraformDir init

if ($LASTEXITCODE -ne 0) {
    throw "terraform init failed."
}

Write-Host "Validating Terraform..."

terraform -chdir=$TerraformDir validate

if ($LASTEXITCODE -ne 0) {
    throw "terraform validate failed."
}

Write-Host "Planning infrastructure..."

terraform -chdir=$TerraformDir plan -out=tfplan

if ($LASTEXITCODE -ne 0) {
    throw "terraform plan failed."
}

Write-Host "Applying infrastructure..."

terraform -chdir=$TerraformDir apply -auto-approve tfplan

if ($LASTEXITCODE -ne 0) {
    throw "terraform apply failed."
}

$AnsibleIp = terraform -chdir=$TerraformDir output -raw ansible01_public_ip

if (-not $AnsibleIp) {
    throw "Impossible de récupérer l'IP publique ANSIBLE01."
}

Write-Host "Validating Ansible connectivity..."

ssh `
    -o StrictHostKeyChecking=no `
    -i "$env:USERPROFILE\.ssh\ansible01" `
    "ubuntu@$AnsibleIp" `
    "ansible rmia -m ansible.windows.win_ping"

if ($LASTEXITCODE -ne 0) {
    throw "Ansible validation failed."
}

Write-Host ""
Write-Host "LAB READY"
Write-Host "ANSIBLE01: $AnsibleIp"