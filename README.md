# DevOps Infrastructure Automation — RMIA WAR Deployment

Ce projet met en œuvre une chaîne CI/CD permettant d'automatiser le déploiement d'applications Java **WAR** sur plusieurs serveurs Windows **RMIA** à l'aide de **GitLab CI/CD** et **Ansible**.

L'infrastructure AWS présente dans ce repository permet de reproduire l'environnement dans un **LAB / POC**.

---

## Architecture

```text
GitLab.com
    │
    │ GitLab CI/CD
    ▼
GitLab SaaS Runner
    │
    │ SSH
    ▼
ANSIBLE01
    │
    │ Ansible / WinRM
    ▼
RMIA01 ── RMIA02 ── ... ── RMIAN
    │
    ▼
Tomcat / WAR
```

Le projet contient deux parties distinctes :

### Infrastructure LAB / POC

Terraform permet de reconstruire sur AWS un environnement simulant l'infrastructure cible :

- réseau AWS ;
- serveur Linux `ANSIBLE01` ;
- serveurs Windows `RMIA01`, `RMIA02`, etc. ;
- configuration réseau et Security Groups ;
- génération de l'inventory Ansible ;
- récupération automatisée des credentials Windows ;
- stockage des secrets Windows avec Ansible Vault.

### Automatisation de déploiement

GitLab CI/CD et Ansible constituent la partie fonctionnelle de la solution.

Dans l'environnement réel :

- les serveurs RMIA sont des VM Windows existantes ;
- Tomcat est déjà installé et configuré ;
- les WAR sont fournis par un système tiers / répertoire partagé ;
- Ansible automatise les opérations de déploiement.

Terraform n'est donc utilisé que pour construire l'environnement de LAB.

---

# Partie I — Préparation de l'infrastructure LAB

## 1. Prérequis

La machine utilisée pour administrer le LAB doit disposer de :

- Git
- Terraform
- AWS CLI
- OpenSSH
- PowerShell

Vérification :

```powershell
git --version
terraform version
aws --version
ssh -V
```

Le projet a été développé principalement depuis Windows avec PowerShell.

---

## 2. Cloner le projet

```bash
git clone <URL_DU_REPOSITORY>
cd devops-infrastructure-automation
```

Vérifier :

```bash
git status
```

---

## 3. Architecture AWS du LAB

Terraform crée notamment :

```text
AWS
│
├── VPC
├── Subnet
├── Security Groups
├── ANSIBLE01
│   └── Ubuntu / Ansible Control Node
├── RMIA01
│   └── Windows Server
└── RMIA02
    └── Windows Server
```

Le LAB utilise actuellement deux serveurs RMIA afin de limiter la consommation de ressources AWS.

Le même principe peut ensuite être étendu à :

```text
RMIA01
RMIA02
RMIA03
...
RMIAN
```

---

## 4. Configurer les credentials AWS

Le LAB utilise le profil AWS :

```text
kodekloud
```

Récupérer les credentials du compte ou du Playground AWS :

```text
AWS Access Key ID
AWS Secret Access Key
```

Configurer le profil :

```powershell
aws configure --profile kodekloud
```

Renseigner :

```text
AWS Access Key ID     : <ACCESS_KEY>
AWS Secret Access Key : <SECRET_KEY>
Default region        : us-east-1
Default output format : json
```

Tester l'accès :

```powershell
aws sts get-caller-identity --profile kodekloud
```

La commande doit retourner l'identité AWS utilisée par Terraform.

> **Important :** ne jamais stocker les credentials AWS dans Git.

---

## 5. Préparer les clés SSH

Deux paires de clés sont utilisées dans le LAB.

### Clé ANSIBLE01

Cette clé permet d'accéder au serveur Linux `ANSIBLE01`.

Fichiers attendus :

```text
~/.ssh/ansible01
~/.ssh/ansible01.pub
```

Sous Windows :

```text
C:\Users\<USER>\.ssh\ansible01
C:\Users\<USER>\.ssh\ansible01.pub
```

Si la clé n'existe pas :

```powershell
ssh-keygen -t ed25519 -f "$env:USERPROFILE\.ssh\ansible01"
```

### Clé RMIA

Cette clé est utilisée par AWS pour permettre la récupération automatisée du mot de passe Administrator des instances Windows.

Fichiers attendus :

```text
~/.ssh/rmia
~/.ssh/rmia.pub
```

Créer la clé si nécessaire :

```powershell
ssh-keygen -t rsa -b 4096 -m PEM -f "$env:USERPROFILE\.ssh\rmia"
```

> Les clés privées ne doivent jamais être ajoutées au repository.

---

## 6. Initialiser Terraform

Depuis la racine du projet :

```powershell
terraform -chdir=terraform init
```

Valider la configuration :

```powershell
terraform -chdir=terraform validate
```

Créer le plan Terraform :

```powershell
terraform -chdir=terraform plan
```

---

## 7. Créer l'infrastructure

Exécuter :

```powershell
terraform -chdir=terraform apply
```

Puis confirmer :

```text
yes
```

Terraform crée notamment :

- ANSIBLE01 ;
- RMIA01 ;
- RMIA02 ;
- le réseau AWS ;
- les Security Groups ;
- l'inventory Ansible ;
- la configuration WinRM ;
- les credentials Windows nécessaires à Ansible ;
- les secrets chiffrés avec Ansible Vault.

---

## 8. Vérifier les outputs Terraform

```powershell
terraform -chdir=terraform output
```

Récupérer automatiquement l'adresse IP publique de `ANSIBLE01` :

```powershell
$AnsibleIp = terraform -chdir=terraform output -raw ansible01_public_ip
```

Vérifier :

```powershell
$AnsibleIp
```

---

## 9. Vérifier ANSIBLE01

Tester la connexion SSH :

```powershell
ssh -i "$env:USERPROFILE\.ssh\ansible01" ubuntu@$AnsibleIp
```

Ou effectuer directement une vérification distante :

```powershell
ssh -i "$env:USERPROFILE\.ssh\ansible01" ubuntu@$AnsibleIp "hostname && ansible --version"
```

Résultat attendu :

```text
ansible01
ansible [core ...]
```

---

## 10. Vérifier les serveurs RMIA

Terraform génère et installe automatiquement l'inventory Ansible sur `ANSIBLE01`.

Tester les connexions WinRM :

```powershell
ssh -i "$env:USERPROFILE\.ssh\ansible01" ubuntu@$AnsibleIp "ansible rmia -m ansible.windows.win_ping"
```

Résultat attendu :

```text
RMIA01 | SUCCESS => {
    "ping": "pong"
}

RMIA02 | SUCCESS => {
    "ping": "pong"
}
```

Tous les RMIA doivent répondre avant de poursuivre.

---

## 11. Installer la configuration fonctionnelle Ansible

Terraform prépare l'infrastructure et les accès Ansible.

Les playbooks fonctionnels sont ensuite installés sur `ANSIBLE01` avec :

```text
scripts/bootstrap-ansible.ps1
```

Exécuter :

```powershell
.\scripts\bootstrap-ansible.ps1 -AnsiblePublicIp $AnsibleIp
```

Le script automatise notamment :

- la création des répertoires Ansible ;
- la copie des playbooks ;
- la création de `/opt/rmia-share` ;
- la création du WAR technique utilisé pour le POC ;
- la validation syntaxique des playbooks ;
- la préparation des serveurs RMIA.

Résultat attendu :

```text
ANSIBLE BOOTSTRAP READY
```

---

## 12. Playbooks Ansible

Les playbooks sont installés sur `ANSIBLE01` dans :

```text
/etc/ansible/playbooks/
```

Notamment :

```text
/etc/ansible/playbooks/deploy-war.yml
/etc/ansible/playbooks/bootstrap-rmia-poc.yml
```

Le WAR technique actuellement utilisé par le POC est :

```text
/opt/rmia-share/ramia-ws.war
```

---

## 13. Tester directement le déploiement Ansible

### Déploiement sur RMIA01

```powershell
ssh -i "$env:USERPROFILE\.ssh\ansible01" ubuntu@$AnsibleIp `
"ansible-playbook /etc/ansible/playbooks/deploy-war.yml --limit RMIA01 -e 'war_file=ramia-ws.war'"
```

Résultat attendu :

```text
PLAY RECAP

RMIA01 : ok=6 changed=... unreachable=0 failed=0
```

### Déploiement sur plusieurs RMIA

```powershell
ssh -i "$env:USERPROFILE\.ssh\ansible01" ubuntu@$AnsibleIp `
"ansible-playbook /etc/ansible/playbooks/deploy-war.yml --limit RMIA01,RMIA02 -e 'war_file=ramia-ws.war'"
```

Résultat attendu :

```text
PLAY RECAP

RMIA01 : ok=6 changed=... unreachable=0 failed=0
RMIA02 : ok=6 changed=... unreachable=0 failed=0
```

---

# Partie II — Automatisation du déploiement

## 14. Principe

Dans l'environnement réel :

- les RMIA existent déjà ;
- Windows est déjà installé ;
- Tomcat est déjà installé et configuré ;
- les WAR sont fournis par un système tiers ou un répertoire partagé.

L'automatisation prend ensuite en charge le déploiement :

```text
Opérateur
    │
    ▼
GitLab
    │
    │ sélection WAR / RMIA
    ▼
GitLab SaaS Runner
    │
    │ SSH
    ▼
ANSIBLE01
    │
    │ Ansible / WinRM
    ▼
RMIA sélectionnés
    │
    ▼
Tomcat
```

---

## 15. Workflow Ansible

Le playbook de déploiement réalise actuellement :

1. chargement de la configuration du RMIA ;
2. arrêt du service Tomcat ;
3. archivage et nettoyage des logs ;
4. copie du WAR dans `webapps` ;
5. redémarrage du service Tomcat ;
6. affichage du résumé de déploiement.

Dans le LAB AWS, certains composants Tomcat sont simulés afin de valider la chaîne d'automatisation sans reproduire l'intégralité de l'environnement applicatif réel.

---

## 16. Configuration GitLab CI/CD

Le pipeline est défini dans :

```text
.gitlab-ci.yml
```

Le GitLab Runner ne communique pas directement avec les serveurs Windows.

La communication est :

```text
GitLab Runner
     │
     │ SSH
     ▼
ANSIBLE01
     │
     │ WinRM
     ▼
RMIA
```

ANSIBLE01 reste donc le Control Node Ansible.

---

## 17. Configurer les variables GitLab

Dans le projet GitLab :

```text
Settings
  → CI/CD
  → Variables
```

Créer les variables suivantes.

### ANSIBLE_HOST

```text
Key   : ANSIBLE_HOST
Value : <IP_PUBLIQUE_ANSIBLE01>
```

Pour le LAB :

```powershell
terraform -chdir=terraform output -raw ansible01_public_ip
```

### ANSIBLE_USER

```text
Key   : ANSIBLE_USER
Value : ubuntu
```

### SSH_PRIVATE_KEY

```text
Key   : SSH_PRIVATE_KEY
Value : contenu de ~/.ssh/ansible01
```

Cette clé permet au GitLab Runner de se connecter à ANSIBLE01.

> **Important :** la clé privée ne doit jamais être stockée directement dans `.gitlab-ci.yml` ou dans le repository.

---

## 18. GitLab SaaS Runner

Le projet utilise les runners SaaS fournis par GitLab.com.

Le job utilise actuellement :

```yaml
image: alpine:latest
```

Le client OpenSSH est installé au démarrage du job afin de permettre la connexion à ANSIBLE01.

La chaîne suivante a été validée :

```text
GitLab.com
     │
     ▼
GitLab SaaS Runner
     │
     │ SSH
     ▼
ANSIBLE01
```

---

## 19. Lancer un déploiement

Dans GitLab :

```text
Build
  → Pipelines
  → New pipeline
```

L'interface permet de sélectionner les WAR et les serveurs cibles.

Exemple :

```text
WAR

☑ ramia-ws.war
☐ rmia-webapp.war
☑ rmia-soap-ws.war
☐ rmia-rest-ws.war

Serveurs

☑ RMIA01
☑ RMIA02
```

Créer le pipeline avec :

```text
Run pipeline
```

Puis lancer le job manuel :

```text
deploy_war
```

---

## 20. Sélection multi-RMIA

Exemple :

```text
☑ RMIA01
☐ RMIA02
☑ RMIA03
☑ RMIA04
```

Le pipeline construit automatiquement :

```text
TARGET_SERVERS=RMIA01,RMIA03,RMIA04
```

Cette valeur est transmise à Ansible :

```bash
ansible-playbook /etc/ansible/playbooks/deploy-war.yml \
  --limit "RMIA01,RMIA03,RMIA04"
```

Le mécanisme peut être étendu jusqu'à :

```text
RMIA01 ... RMIA20
```

---

## 21. Sélection multi-WAR

L'interface GitLab prévoit actuellement :

```text
ramia-ws.war
rmia-webapp.war
rmia-soap-ws.war
rmia-rest-ws.war
```

Plusieurs WAR peuvent être sélectionnés.

Exemple :

```text
☑ ramia-ws.war
☐ rmia-webapp.war
☑ rmia-soap-ws.war
☑ rmia-rest-ws.war
```

### Limitation actuelle du POC

Pour le moment, la sélection multi-WAR valide uniquement l'interface GitLab.

Le backend du POC déploie volontairement toujours :

```text
ramia-ws.war
```

La prochaine évolution permettra de transmettre réellement tous les WAR sélectionnés au playbook Ansible.

---

# Partie III — Recréation rapide du LAB

## 22. Procédure après reset AWS / KodeKloud

### Étape 1 — Configurer les nouveaux credentials

```powershell
aws configure --profile kodekloud
```

Tester :

```powershell
aws sts get-caller-identity --profile kodekloud
```

### Étape 2 — Initialiser Terraform

```powershell
terraform -chdir=terraform init
```

### Étape 3 — Valider Terraform

```powershell
terraform -chdir=terraform validate
```

### Étape 4 — Vérifier le plan

```powershell
terraform -chdir=terraform plan
```

### Étape 5 — Créer l'infrastructure

```powershell
terraform -chdir=terraform apply
```

### Étape 6 — Récupérer l'IP de ANSIBLE01

```powershell
$AnsibleIp = terraform -chdir=terraform output -raw ansible01_public_ip
```

### Étape 7 — Vérifier ANSIBLE01

```powershell
ssh -i "$env:USERPROFILE\.ssh\ansible01" ubuntu@$AnsibleIp "hostname && ansible --version"
```

### Étape 8 — Vérifier les RMIA

```powershell
ssh -i "$env:USERPROFILE\.ssh\ansible01" ubuntu@$AnsibleIp `
"ansible rmia -m ansible.windows.win_ping"
```

### Étape 9 — Installer les playbooks

```powershell
.\scripts\bootstrap-ansible.ps1 -AnsiblePublicIp $AnsibleIp
```

Résultat attendu :

```text
ANSIBLE BOOTSTRAP READY
```

### Étape 10 — Mettre à jour GitLab

Dans :

```text
Settings
  → CI/CD
  → Variables
```

mettre à jour :

```text
ANSIBLE_HOST=<NOUVELLE_IP_ANSIBLE01>
```

### Étape 11 — Lancer le pipeline

```text
Build
  → Pipelines
  → New pipeline
```

Sélectionner :

- le ou les WAR ;
- le ou les RMIA.

Puis lancer :

```text
deploy_war
```

---

## 23. Résumé des commandes de reconstruction

```powershell
aws configure --profile kodekloud

aws sts get-caller-identity --profile kodekloud

terraform -chdir=terraform init

terraform -chdir=terraform validate

terraform -chdir=terraform plan

terraform -chdir=terraform apply

$AnsibleIp = terraform -chdir=terraform output -raw ansible01_public_ip

ssh -i "$env:USERPROFILE\.ssh\ansible01" ubuntu@$AnsibleIp `
"ansible rmia -m ansible.windows.win_ping"

.\scripts\bootstrap-ansible.ps1 -AnsiblePublicIp $AnsibleIp
```

Ensuite mettre à jour :

```text
ANSIBLE_HOST=<NOUVELLE_IP>
```

dans GitLab, puis lancer le pipeline.

---

# Sécurité

Les éléments suivants ne doivent jamais être versionnés :

- AWS Access Key ;
- AWS Secret Access Key ;
- clés SSH privées ;
- mot de passe Administrator Windows ;
- mot de passe Ansible Vault ;
- credentials GitLab ;
- secrets applicatifs.

Les secrets Windows nécessaires au LAB sont stockés chiffrés avec **Ansible Vault**.

Les secrets nécessaires au pipeline sont gérés via les **GitLab CI/CD Variables**.

---

# État actuel du POC

Les éléments suivants ont été validés :

- Terraform → AWS ;
- création de ANSIBLE01 ;
- création de RMIA01 et RMIA02 ;
- configuration WinRM ;
- génération de l'inventory Ansible ;
- récupération automatisée des credentials Windows ;
- Ansible Vault ;
- ANSIBLE01 → RMIA via WinRM ;
- déploiement WAR avec Ansible ;
- déploiement mono-RMIA ;
- déploiement multi-RMIA ;
- GitLab.com SaaS Runner ;
- GitLab Runner → ANSIBLE01 via SSH ;
- sélection multi-RMIA ;
- interface de sélection multi-WAR ;
- GitLab → Ansible → RMIA.

Chaîne validée :

```text
GitLab.com
     │
     ▼
GitLab SaaS Runner
     │
     │ SSH
     ▼
ANSIBLE01
     │
     │ Ansible / WinRM
     ▼
RMIA01 + RMIA02
     │
     ▼
WAR Deployment
```

---

# Prochaines évolutions

- prise en charge réelle de plusieurs WAR ;
- extension de la sélection jusqu'à RMIA20 ;
- adaptation aux vrais noms de services Tomcat ;
- intégration du véritable répertoire partagé contenant les WAR ;
- contrôles applicatifs post-déploiement ;
- amélioration des logs et rapports ;
- sécurisation de l'accès SSH à ANSIBLE01 ;
- adaptation finale à l'environnement Windows on-premise cible.
