# 🔄 Procédure de reprise du Lab après réinitialisation KodeKloud

## ⚠️ Particularité du KodeKloud AWS Playground

Le **AWS Playground KodeKloud est disponible pendant environ 3 heures**.

À l'expiration du délai, l'environnement est réinitialisé :

* les ressources AWS créées peuvent disparaître ;
* les credentials AWS peuvent changer ;
* les instances EC2 peuvent être supprimées ;
* les VPC, Subnets, Security Groups, etc. peuvent être recréés à zéro.

Le code du projet présent sur la machine locale **n'est pas concerné par le reset du playground**.

L'objectif du projet est donc de pouvoir **reconstruire toute l'infrastructure uniquement à partir du code Terraform**.

---

# 1. Récupérer les nouveaux credentials AWS

Après chaque réinitialisation du playground, récupérer dans KodeKloud :

```text
Access Key
Secret Key
```

> ⚠️ Ne jamais mettre ces credentials directement dans le code Terraform ou dans Git.

---

# 2. Mettre à jour le profil AWS CLI

Le projet utilise le profil :

```text
kodekloud
```

Exécuter :

```powershell
aws configure --profile kodekloud
```

Renseigner :

```text
AWS Access Key ID     → nouveau Access Key
AWS Secret Access Key → nouveau Secret Key
Default region name   → us-east-1
Default output format → laisser vide
```

La région utilisée par le lab est :

```text
us-east-1
```

---

# 3. Vérifier les credentials

Exécuter :

```powershell
aws sts get-caller-identity --profile kodekloud
```

Si la commande retourne les informations du compte AWS :

```json
{
    "UserId": "...",
    "Account": "...",
    "Arn": "arn:aws:iam::..."
}
```

Alors l'authentification fonctionne.

✅ **AWS CLI connecté**

---

# 4. Vérifier la région

```powershell
aws configure get region --profile kodekloud
```

Résultat attendu :

```text
us-east-1
```

Si nécessaire :

```powershell
aws configure set region us-east-1 --profile kodekloud
```

---

# 5. Vérifier les outils locaux

Vérifier AWS CLI :

```powershell
aws --version
```

Vérifier Terraform :

```powershell
terraform --version
```

Vérifier Git :

```powershell
git --version
```

Les trois commandes doivent fonctionner.

---

# 6. Revenir dans le projet

Depuis PowerShell :

```powershell
cd C:\developpement\ansible-windows-cicd-lab
```

Vérifier Git :

```powershell
git status
```

Puis vérifier la structure :

```powershell
Get-ChildItem
```

---

# 7. Vérifier Terraform

Entrer dans le répertoire Terraform :

```powershell
cd terraform
```

Initialiser Terraform :

```powershell
terraform init
```

Puis vérifier la configuration :

```powershell
terraform validate
```

Résultat attendu :

```text
Success! The configuration is valid.
```

---

# 8. ⚠️ Vérifier le Terraform State après un reset

Après une réinitialisation AWS, **ne pas exécuter directement `terraform apply`**.

Le fichier Terraform State peut encore contenir les anciennes ressources AWS.

Vérifier d'abord :

```powershell
terraform state list
```

Puis :

```powershell
terraform plan
```

### Cas 1 — les ressources AWS existent encore

Terraform peut les retrouver et continuer à les gérer.

### Cas 2 — les ressources AWS ont disparu

Le playground a probablement été réinitialisé.

Dans ce cas, on décide ensemble s'il faut :

* recréer les ressources ;
* supprimer/recréer le state local ;
* ou effectuer une récupération propre du state.

> ⚠️ Ne pas supprimer le state automatiquement sans vérifier la situation.

---

# 9. Vérifier l'accès AWS depuis Terraform

Le provider AWS du projet utilise le profil :

```hcl
provider "aws" {
  region  = "us-east-1"
  profile = "kodekloud"
}
```

Tester ensuite :

```powershell
terraform plan
```

Terraform doit pouvoir communiquer avec AWS.

---

# 10. Reconstruction de l'infrastructure

L'objectif final du projet est d'avoir une infrastructure **100 % reproductible**.

Après un reset, nous voulons pouvoir faire :

```text
Nouveaux credentials
        │
        ▼
aws configure
        │
        ▼
aws sts get-caller-identity
        │
        ▼
terraform init
        │
        ▼
terraform validate
        │
        ▼
terraform plan
        │
        ▼
terraform apply
        │
        ▼
Infrastructure complète recréée
```

Terraform devra créer lui-même les ressources nécessaires :

```text
AWS
│
├── VPC
│   ├── Subnets
│   ├── Route Tables
│   └── Internet Gateway
│
├── Security Groups
│
├── EC2
│   └── ANSIBLE01
│
└── autres ressources nécessaires
```

Les ressources AWS préexistantes du playground ne doivent pas être considérées comme des dépendances du projet.

---

# 11. Règles de sécurité

Les credentials AWS ne doivent **jamais** être commités dans Git.

Le fichier suivant est volontairement ignoré :

```text
playground-credentials.json
```

Vérifier :

```powershell
git status --ignored
```

Le fichier doit apparaître dans :

```text
Ignored files
```

Les fichiers Terraform suivants peuvent être versionnés :

```text
main.tf
variables.tf
outputs.tf
versions.tf
.terraform.lock.hcl
```

Le répertoire suivant ne doit pas être versionné :

```text
.terraform/
```

Les fichiers State ne doivent pas être versionnés :

```text
*.tfstate
*.tfstate.*
```

---

# 12. Checklist rapide à chaque nouvelle session

```text
[ ] Playground KodeKloud démarré
[ ] Vérifier le temps restant
[ ] Récupérer Access Key
[ ] Récupérer Secret Key
[ ] aws configure --profile kodekloud
[ ] Vérifier région = us-east-1
[ ] aws sts get-caller-identity --profile kodekloud
[ ] Vérifier aws --version
[ ] Vérifier terraform --version
[ ] Vérifier git status
[ ] cd terraform
[ ] terraform init
[ ] terraform validate
[ ] terraform state list
[ ] terraform plan
[ ] Vérifier la situation avant terraform apply
```

---

# 🎯 Objectif du lab

Le lab doit rester fonctionnel même après une réinitialisation complète du KodeKloud AWS Playground.

**Principe fondamental :**

> Le code Terraform est la source de vérité de l'infrastructure.

Nous ne devons pas dépendre d'un VPC, d'un Subnet, d'un Security Group ou d'une EC2 créée manuellement dans le playground.

L'infrastructure doit pouvoir être détruite puis reconstruite à partir du dépôt Git.

```text
Git
 │
 ▼
Terraform
 │
 ▼
AWS
 │
 ├── VPC
 ├── Network
 ├── Security Groups
 └── EC2 / ANSIBLE01
```
