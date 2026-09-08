# Configure WinRM HTTPS for Ansible

$ErrorActionPreference = "Stop"

# Ensure WinRM service is running
Set-Service -Name WinRM -StartupType Automatic
Start-Service -Name WinRM

# Create a self-signed certificate for the local computer
$cert = New-SelfSignedCertificate `
    -DnsName $env:COMPUTERNAME `
    -CertStoreLocation "Cert:\LocalMachine\My" `
    -KeyLength 2048 `
    -KeyAlgorithm RSA `
    -HashAlgorithm SHA256

$thumbprint = $cert.Thumbprint

# Remove existing HTTPS listeners
Get-ChildItem WSMan:\localhost\Listener |
    Where-Object { $_.Keys -match "Transport=HTTPS" } |
    ForEach-Object {
        Remove-Item -Path $_.PSPath -Recurse -Force
    }

# Create WinRM HTTPS listener
New-Item `
    -Path WSMan:\localhost\Listener `
    -Transport HTTPS `
    -Address * `
    -CertificateThumbPrint $thumbprint `
    -Force

# Allow WinRM HTTPS from ANSIBLE01
New-NetFirewallRule `
    -DisplayName "WinRM HTTPS 5986" `
    -Direction Inbound `
    -Protocol TCP `
    -LocalPort 5986 `
    -Action Allow

# Restart WinRM
Restart-Service WinRM