# Ansible Windows CI/CD Lab

## Objectif

Construire une infrastructure reproductible permettant de déployer
des artefacts WAR fournis par un tiers sur un parc Windows/Tomcat.

## Architecture cible

GitHub
→ GitLab
→ GitLab CI/CD
→ GitLab Runner
→ Ansible
→ WinRM
→ Windows/Tomcat
→ WAR

## Infrastructure

- AWS EC2
- Terraform
- Ansible
- Windows Server
- Tomcat
- GitLab CI/CD


## limite des resources 
EC2

Régions disponibles : us-east-1, us-west-2, us-east-2
Pour Windows : supporté
Types autorisés : t2.* et t3.* jusqu'à medium
Maximum : 2 vCPU / 4 GiB par instance
Maximum : 10 instances
Maximum global : 10 vCPU / 20 GiB RAM
EBS : 30 GB maximum, uniquement GP2/GP3
CPU credits = Standard obligatoire
Pas de Spot, Dedicated Hosts, Capacity Reservations, etc.
Le comportement d'arrêt est terminate.