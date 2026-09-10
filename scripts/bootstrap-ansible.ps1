<#
.SYNOPSIS
Bootstrap de la configuration fonctionnelle Ansible sur ANSIBLE01.

.DESCRIPTION
Ce script prépare ANSIBLE01 pour le POC de déploiement WAR :
- création des répertoires Ansible
- copie des playbooks
- création du répertoire source des WAR
- création du WAR de test
- validation de la syntaxe des playbooks
- préparation des serveurs RMIA pour le POC

UTILISATION APRES UN RESET KODEKLOUD

1. Reconstruire l'infrastructure avec Terraform.

2. Récupérer automatiquement l'IP publique de ANSIBLE01 :

   $AnsibleIp = terraform -chdir=terraform output -raw ansible01_public_ip

3. Exécuter le bootstrap Ansible :

   .\scripts\bootstrap-ansible.ps1 -AnsiblePublicIp $AnsibleIp

#>

param (
    [Parameter(Mandatory = $true)]
    [string]$AnsiblePublicIp
)

$ErrorActionPreference = "Stop"

$ScriptDir   = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectRoot = Split-Path -Parent $ScriptDir

$SshKey = "$env:USERPROFILE\.ssh\ansible01"

$DeployPlaybook = Join-Path `
    $ProjectRoot `
    "ansible\playbooks\deploy-war.yml"

$BootstrapPlaybook = Join-Path `
    $ProjectRoot `
    "ansible\playbooks\bootstrap-rmia-poc.yml"


Write-Host "Checking local files..."

if (-not (Test-Path $SshKey)) {
    throw "SSH key introuvable : $SshKey"
}

if (-not (Test-Path $DeployPlaybook)) {
    throw "Playbook introuvable : $DeployPlaybook"
}

if (-not (Test-Path $BootstrapPlaybook)) {
    throw "Playbook introuvable : $BootstrapPlaybook"
}


Write-Host "Preparing Ansible directories on ANSIBLE01..."

ssh `
    -o StrictHostKeyChecking=no `
    -i $SshKey `
    "ubuntu@$AnsiblePublicIp" `
    "sudo mkdir -p /etc/ansible/playbooks /opt/rmia-share && sudo chown -R ubuntu:ubuntu /etc/ansible/playbooks /opt/rmia-share"

if ($LASTEXITCODE -ne 0) {
    throw "Unable to prepare ANSIBLE01 directories."
}


Write-Host "Copying Ansible playbooks..."

scp `
    -o StrictHostKeyChecking=no `
    -i $SshKey `
    $DeployPlaybook `
    $BootstrapPlaybook `
    "ubuntu@${AnsiblePublicIp}:/tmp/"

if ($LASTEXITCODE -ne 0) {
    throw "Unable to copy Ansible playbooks."
}


Write-Host "Installing Ansible playbooks..."

ssh `
    -o StrictHostKeyChecking=no `
    -i $SshKey `
    "ubuntu@$AnsiblePublicIp" `
    "sudo cp /tmp/deploy-war.yml /tmp/bootstrap-rmia-poc.yml /etc/ansible/playbooks/ && sudo chown ubuntu:ubuntu /etc/ansible/playbooks/*.yml"

if ($LASTEXITCODE -ne 0) {
    throw "Unable to install Ansible playbooks."
}


Write-Host "Creating POC WAR..."

ssh `
    -o StrictHostKeyChecking=no `
    -i $SshKey `
    "ubuntu@$AnsiblePublicIp" `
    "rm -rf /tmp/war-test && mkdir -p /tmp/war-test/WEB-INF && echo '<html><body><h1>RMIA WAR deployment POC</h1></body></html>' > /tmp/war-test/index.html && cd /tmp && python3 -m zipfile -c /opt/rmia-share/ramia-ws.war war-test/index.html"

if ($LASTEXITCODE -ne 0) {
    throw "Unable to create POC WAR."
}


Write-Host "Checking Ansible playbooks syntax..."

ssh `
    -o StrictHostKeyChecking=no `
    -i $SshKey `
    "ubuntu@$AnsiblePublicIp" `
    "ansible-playbook /etc/ansible/playbooks/bootstrap-rmia-poc.yml --syntax-check && ansible-playbook /etc/ansible/playbooks/deploy-war.yml --syntax-check"

if ($LASTEXITCODE -ne 0) {
    throw "Ansible syntax check failed."
}


Write-Host "Preparing RMIA POC environment..."

ssh `
    -o StrictHostKeyChecking=no `
    -i $SshKey `
    "ubuntu@$AnsiblePublicIp" `
    "ansible-playbook /etc/ansible/playbooks/bootstrap-rmia-poc.yml"

if ($LASTEXITCODE -ne 0) {
    throw "RMIA POC bootstrap failed."
}


Write-Host ""
Write-Host "ANSIBLE BOOTSTRAP READY"
Write-Host "ANSIBLE01 : $AnsiblePublicIp"
Write-Host "WAR source : /opt/rmia-share/ramia-ws.war"
Write-Host "Deploy playbook : /etc/ansible/playbooks/deploy-war.yml"