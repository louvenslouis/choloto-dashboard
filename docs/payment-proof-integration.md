# Abonnement VIP par preuve de paiement

## Parcours livré

- Application : Paramètres → Abonnement par preuve de paiement. Un second accès se trouve sur l’écran d’abonnement existant.
- Le membre doit être connecté. Le formulaire contient seulement le choix d’une photo, un message facultatif et le bouton « Envoyer ». La photo représente la preuve d’un virement ou d’un portefeuille numérique externe. Aucun montant, moyen de paiement ou référence n’est demandé au membre.
- La soumission en ligne lit d’abord la demande puis `/user/{uid}`. Elle crée ensemble la demande et sa preuve. Elle ne modifie jamais l’abonnement.
- Le membre suit ses demandes en temps réel : en attente, paiement validé avec échéance et code du reçu, ou refus avec motif. Une nouvelle demande peut être envoyée après un refus.
- Dashboard : compteur des demandes en attente sur l’accueil et entrée « Preuves de paiement » dans la navigation. Filtres en attente, validées, refusées et toutes.
- L’administrateur ouvre la preuve avec zoom, vérifie l’identité issue du profil et les informations du transfert, puis saisit le montant, la devise, le moyen de paiement et l’échéance VIP. La date proposée ajoute un mois à l’échéance actuelle encore valide, ou à aujourd’hui si le plan a expiré.
- La validation relit la demande et le profil actuels et enregistre, dans une seule transaction : `user.end_sub`, `method`, `member_time`, `updated_time`, le paiement historique et la décision. La date choisie doit prolonger le plan actuel.
- Le refus exige un motif visible par le membre et ne crée aucun paiement. Une preuve absente/illisible désactive la validation mais permet le refus.
- Le reçu PDF utilise le générateur existant du dashboard. Un échec de téléchargement ne relance pas la validation : le reçu reste téléchargeable depuis la demande acceptée et depuis le parcours de paiement existant.

## Stockage et confidentialité

`payment_requests/{id}` conserve à l’envoi : `user_uid`, `plan: vip`, `status: pending`, `note` (vide si aucun message), `created_at`. Lors de la validation, l’administrateur ajoute `amount`, `currency` et `payment_method`, qui doivent correspondre au paiement enregistré dans la même transaction. Les anciennes demandes comportant déjà ces champs et `payment_reference` restent lisibles et acceptées. Les seules devises sont celles du registre existant : `GDS` et `USD`.

`payment_requests/{id}/evidence/image` conserve `base64`, `mime_type: image/jpeg` et `byte_length`. La photo est chargée uniquement à l’ouverture du détail, puis décodée pour l’affichage. Les listes ne chargent jamais les photos. L’indexation de `evidence.base64` est désactivée dans les deux configurations d’index.

Les images source sont limitées à 12 Mio et 24 mégapixels. Le client contrôle le type réel, corrige l’orientation, retire les métadonnées EXIF/GPS, réduit le grand côté à 1600 pixels et encode un JPEG de 600 000 octets maximum, soit au plus 800 000 caractères Base64. Cette marge respecte la limite Firestore de 1 Mio par document ([documentation Firebase](https://firebase.google.com/docs/firestore/quotas)). Le sélecteur lit le fichier par blocs après contrôle de la taille déclarée.

Seuls le propriétaire et les administrateurs déjà reconnus par les règles peuvent lire une demande et sa preuve. Les preuves sont immuables. Le membre ne peut ni accepter sa demande, ni créer un paiement. Les nouvelles règles imposent l’écriture atomique du profil et du paiement lors d’une acceptation, en s’appuyant sur `getAfter` ([documentation Firebase](https://firebase.google.com/docs/firestore/security/rules-conditions)).

La transaction liée est `payment_transactions/proof_{id}` et son reçu `CH-proof_{id}`. Cet identifiant fixe, le statut terminal et la relecture transactionnelle empêchent une double validation de la même demande. Une nouvelle demande reste une demande distincte : l’administrateur doit vérifier la référence pour identifier un reçu déjà soumis dans une autre demande.

## Compatibilité préservée

Les anciens chemins et droits de `/user/{uid}`, les paiements manuels du dashboard, leurs champs, les reçus PDF, les annulations et l’historique d’abonnement du membre restent inchangés. Le nouveau paiement respecte intégralement le schéma `payment_transactions` existant. Les profils historiques sans `uid` ou `member_time` sont pris en charge.

Les ajouts de règles et d’index existent dans les deux dépôts sans remplacer leurs autres règles, qui présentent déjà des différences. Ne pas recopier aveuglément tout le fichier de règles d’un dépôt dans l’autre. Les modifications locales préexistantes du dashboard sont conservées.

La navigation principale de l’application reste Accueil, Tirages, VIP, Tchala. Le nouveau parcours utilise les thèmes et composants de chaque application. Les textes du module sont disponibles en français, anglais et créole ; le dashboard conserve son sélecteur de langue global existant, actuellement français uniquement.

## Validation

Depuis `choloto app/firebase` :

```sh
firebase emulators:exec --only firestore,auth --project demo-choloto "node tests/firestore_rules_compatibility.mjs"
```

Depuis `c_h_o_l_o_t_o_dashboard/firebase` :

```sh
firebase emulators:exec --only firestore,auth --project demo-choloto "node tests/payment_transactions_rules.mjs"
```

Ces deux suites appellent `tests/payment_requests_rules.mjs`. Elles couvrent la lecture préalable des ressources absentes, les profils actuels/historiques, les accès propriétaire/administrateur/étranger/anonyme, les écritures incomplètes, les images trop grandes ou mal typées, les requêtes d’historique, l’acceptation atomique, le montant incohérent, la double validation, le refus, la nouvelle soumission et le profil supprimé. Le nouveau test échoue avec les anciennes règles dès la lecture préalable de la demande, et passe avec les nouvelles.

Tests Flutter application :

```sh
flutter test test/payment_submission_service_test.dart test/payment_proof_test.dart test/theme_test.dart test/subscription_transactions_panel_test.dart test/navigation_responsive_test.dart
```

Tests Flutter dashboard :

```sh
flutter test test/payment_review_service_test.dart test/payment_review_widget_test.dart test/payment_transaction_record_test.dart test/payment_receipt_exporter_test.dart
```

Les tests exécutent le service Dart réel avec un adaptateur de transaction en mémoire, et les permissions avec les émulateurs Firebase. Les tests d’interface couvrent 320 et 1440 pixels, les deux thèmes et les trois langues, les champs obligatoires, le chargement, l’échec/reprise, les doubles clics et la preuve absente. Les captures locales utilisent les polices réelles. Les builds Web vérifient l’intégration des routes et des dépendances ; les sélecteurs natifs Android/iOS n’ont pas été essayés sur des appareils physiques.

## Résultats de validation locale

- 47 tests Flutter ciblés côté application et 25 côté dashboard : réussis, y compris l’envoi sans message, le message facultatif et le montant renseigné par l’administrateur.
- Suites Firebase des deux dépôts sur `demo-choloto` : réussies, y compris les contrats historiques.
- Vérification avec les anciennes règles : échec attendu du nouveau scénario (403 au lieu du 404 préalable).
- Builds Web des deux applications : réussis.
- Analyse des nouveaux modules et de leurs tests : aucun diagnostic.
- `flutter analyze` global : aucun diagnostic de type erreur ; avertissements et informations subsistent dans les fichiers préexistants des deux projets. Ces analyses ne sont donc pas entièrement vertes.
- `git diff --check` : réussi.

## Mise en production

Aucun déploiement n’a été effectué. Cette fonctionnalité nécessite les nouvelles règles Firestore, l’exemption d’index Base64, puis la publication des nouvelles versions de l’application et du dashboard. Elle n’ajoute aucune Cloud Function et n’utilise pas Firebase Storage.

Avant une publication explicitement autorisée, vérifier la version des règles en production et préserver ses autres contrats. Les nouvelles règles doivent précéder les nouveaux clients. Les anciens clients continuent leurs parcours habituels.
