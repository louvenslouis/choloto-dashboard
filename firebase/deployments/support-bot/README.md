# Déploiement Firebase du bot de support

Projet : `choloto-6aa5b`. Cible : `firestore:rules` uniquement.
Publication vérifiée : `2026-09-24T12:06:50.665316Z`.

- Ancien ruleset : `projects/choloto-6aa5b/rulesets/d3cafebb-4c30-406c-b7ed-2c15deed2e5c`.
- Nouveau ruleset : `projects/choloto-6aa5b/rulesets/746da763-a94f-4408-8f1a-8547e98de527`.
- SHA-256 du fichier publié : `ffaf135e5ac8524fac7bbd8bc90a04aecb11b11fecbdada65f9b331088852a8e`.

`production-before.rules` est la sauvegarde exacte des règles actives avant publication. `firestore.rules` ajoute uniquement le bloc `match /support_bot/{document}`. Le retrait de ce bloc restitue exactement la sauvegarde, sans modification des autres règles. Les sources actives ont été relues après déploiement et sont identiques au fichier testé.

Les 13 contrôles du bot passent sur émulateur, ainsi que la suite `choloto app/firebase/tests/firestore_rules_compatibility.mjs` : compatibilité Firestore, parcours client/admin des justificatifs de paiement et notes vocales. Les avertissements de compilation concernent la fonction préexistante `hasActiveVipAccess`, conservée sans modification.

Aucune donnée de production, règle Storage, Function, configuration Hosting ou index n’a été modifié. Les interfaces client et dashboard doivent être publiées séparément.

Commande exécutée depuis ce dossier :

```sh
firebase deploy --only firestore:rules --project choloto-6aa5b --non-interactive
```
