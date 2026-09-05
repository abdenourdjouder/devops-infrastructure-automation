### Gestion des accès d'administration

Dans le cadre du laboratoire, un mécanisme d'accès SSH dédié à la plateforme est mis en œuvre pour permettre l'administration du nœud de contrôle ANSIBLE01.

La clé publique est intégrée à l'infrastructure provisionnée par Terraform, tandis que la clé privée reste exclusivement détenue sur le poste d'administration et n'est jamais intégrée au dépôt de code.

Cette approche permet de démontrer un principe essentiel de la solution : **les composants d'infrastructure et leurs paramètres d'accès nécessaires à leur fonctionnement sont gérés de manière reproductible et automatisée**.

> **Positionnement pour la solution cible client :** le mécanisme présenté dans ce laboratoire constitue une implémentation de référence destinée à valider l'architecture et les principes d'automatisation. Dans le cadre d'un déploiement en production, le modèle de gestion des accès devra être défini et validé avec les équipes Sécurité et Architecture du client, conformément aux politiques et standards de sécurité en vigueur. Selon ces exigences, l'accès pourra notamment s'appuyer sur une gestion centralisée des identités et des privilèges, un bastion d'administration, une solution PAM, un coffre-fort de secrets ou tout autre mécanisme retenu par le client.
