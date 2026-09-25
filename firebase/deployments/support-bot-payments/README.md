# Publication des règles des moyens de paiement du bot

Projet : `choloto-6aa5b`. Publication vérifiée : `2026-09-24T23:42:59.650770Z`.

Seul le bloc `/support_bot/{document}` est étendu : champ `paymentMethods` optionnel, liste limitée à 20 éléments. Les configurations sans ce champ restent autorisées. Les autres règles restent identiques à la production sauvegardée ; aucune donnée existante n’a été modifiée.

Avant : `projects/choloto-6aa5b/rulesets/746da763-a94f-4408-8f1a-8547e98de527`.
Après : `projects/choloto-6aa5b/rulesets/10f9c6ab-e06a-4109-93d4-0bbb381c88ad`.
SHA-256 : `f4ee0b12119f767d317a5d79b0b3c4a9d5cb3277915c84755bb8e14095303554`.

Validation : 19 contrôles du bot et suite générale de compatibilité (Firestore, justificatifs de paiement, notes vocales) réussis sur la source exacte déployée. Relecture de la source active après déploiement : identique au fichier local. Les anciens avertissements liés à `hasActiveVipAccess` restent inchangés.

Commande depuis ce dossier :

```sh
firebase deploy --only firestore:rules --project choloto-6aa5b --non-interactive
```

Les interfaces dashboard et client sont à publier séparément.
