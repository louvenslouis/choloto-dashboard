# Publication des règles des plans du bot

Projet : `choloto-6aa5b`. Cible : `firestore:rules` uniquement.
Publication vérifiée : `2026-09-25T01:41:29.362125Z`.

Seul le bloc `/support_bot/{document}` est étendu : champ `plans` optionnel, liste limitée à 30 éléments. Les documents sans ce champ et les anciens moyens de paiement restent autorisés. Les autres règles sont identiques à la sauvegarde de production.

- Avant : `projects/choloto-6aa5b/rulesets/10f9c6ab-e06a-4109-93d4-0bbb381c88ad`.
- Après : `projects/choloto-6aa5b/rulesets/f09faacd-09ef-4fde-8930-afde7f299818`.
- SHA-256 du fichier publié : `c53b7e3d74344cd9a475234b30987b2b313fbfc4c1ad8aacc68181e2de7cc21b`.

Les tests du bot et la suite de compatibilité Firestore, justificatifs de paiement et notes vocales passent sur la source exacte publiée. La source active a été relue après publication et correspond au fichier `firestore.rules`. Les avertissements de compilation liés à `hasActiveVipAccess` sont préexistants et inchangés.

`production-before.rules` contient la sauvegarde exacte des règles actives avant publication. Les interfaces dashboard, application et landing page sont à publier séparément.

Commande exécutée depuis ce dossier :

```sh
firebase deploy --only firestore:rules --project choloto-6aa5b --non-interactive
```
