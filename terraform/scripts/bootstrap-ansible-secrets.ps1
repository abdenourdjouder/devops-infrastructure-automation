param (
    [Parameter(Mandatory = $true)]
    [string]$AnsiblePublicIp,

    [Parameter(Mandatory = $true)]
    [string]$Rmia01InstanceId,

    [Parameter(Mandatory = $true)]
    [string]$Rmia02InstanceId
)

$ErrorActionPreference = "Stop"

$sshKey    = "$env:USERPROFILE\.ssh\ansible01"
$rmiaKey   = "$env:USERPROFILE\.ssh\rmia"
$awsProfile = "kodekloud"

Write-Host "Retrieving RMIA01 Administrator password..."
$rmia01Password = aws ec2 get-password-data `
    --instance-id $Rmia01InstanceId `
    --priv-launch-key $rmiaKey `
    --profile $awsProfile `
    --query PasswordData `
    --output text

Write-Host "Retrieving RMIA02 Administrator password..."
$rmia02Password = aws ec2 get-password-data `
    --instance-id $Rmia02InstanceId `
    --priv-launch-key $rmiaKey `
    --profile $awsProfile `
    --query PasswordData `
    --output text

if ([string]::IsNullOrWhiteSpace($rmia01Password)) {
    throw "RMIA01 password is not available."
}

if ([string]::IsNullOrWhiteSpace($rmia02Password)) {
    throw "RMIA02 password is not available."
}

$tempDirectory = Join-Path $env:TEMP "devops-lab-ansible"

New-Item -ItemType Directory -Force -Path $tempDirectory | Out-Null

$rmia01File = Join-Path $tempDirectory "RMIA01.yml"
$rmia02File = Join-Path $tempDirectory "RMIA02.yml"

@"
ansible_user: Administrator
ansible_password: '$($rmia01Password.Replace("'", "''"))'
"@ | Set-Content -Path $rmia01File -Encoding UTF8

@"
ansible_user: Administrator
ansible_password: '$($rmia02Password.Replace("'", "''"))'
"@ | Set-Content -Path $rmia02File -Encoding UTF8

try {

    Write-Host "Preparing Ansible Vault on ANSIBLE01..."

   ssh `
    -o StrictHostKeyChecking=no `
    -i $sshKey `
    "ubuntu@$AnsiblePublicIp" `
    "sudo mkdir -p /etc/ansible/inventory/host_vars && sudo chown ubuntu:ubuntu /etc/ansible/inventory/host_vars && if [ ! -f /etc/ansible/.vault_pass ]; then openssl rand -base64 48 | tr -d '\n' | sudo tee /etc/ansible/.vault_pass >/dev/null; fi && sudo chown ubuntu:ubuntu /etc/ansible/.vault_pass && sudo chmod 600 /etc/ansible/.vault_pass && sudo grep -q '^vault_password_file' /etc/ansible/ansible.cfg || echo 'vault_password_file = /etc/ansible/.vault_pass' | sudo tee -a /etc/ansible/ansible.cfg >/dev/null"
    
    Write-Host "Copying RMIA credentials..."

    scp `
        -o StrictHostKeyChecking=no `
        -i $sshKey `
        $rmia01File `
        "ubuntu@${AnsiblePublicIp}:/etc/ansible/inventory/host_vars/RMIA01.yml"

    scp `
        -o StrictHostKeyChecking=no `
        -i $sshKey `
        $rmia02File `
        "ubuntu@${AnsiblePublicIp}:/etc/ansible/inventory/host_vars/RMIA02.yml"

    Write-Host "Encrypting credentials with Ansible Vault..."

    ssh `
        -o StrictHostKeyChecking=no `
        -i $sshKey `
        "ubuntu@$AnsiblePublicIp" `
        "ansible-vault encrypt /etc/ansible/inventory/host_vars/RMIA01.yml /etc/ansible/inventory/host_vars/RMIA02.yml --vault-password-file /etc/ansible/.vault_pass && chmod 600 /etc/ansible/inventory/host_vars/RMIA01.yml /etc/ansible/inventory/host_vars/RMIA02.yml"

    Write-Host "Ansible credentials successfully configured."
}
finally {

    Remove-Item $rmia01File -Force -ErrorAction SilentlyContinue
    Remove-Item $rmia02File -Force -ErrorAction SilentlyContinue

    $rmia01Password = $null
    $rmia02Password = $null
}