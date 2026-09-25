# Bot du service client

Le chat client lit `support_bot/config` en temps réel. Le dashboard expose l’éditeur dans **Service client → Bot du service client**. Chaque branche propose les options **Connexion obligatoire** et **Demander une image**. Les choix et les réponses sont libres et commencent en créole haïtien. L’interface des commandes client suit la langue de l’application.

L’éditeur permet de modifier l’accueil, ajouter des choix et des sous-choix, modifier les réponses, réordonner les choix frères et supprimer une branche. **Publier** enregistre l’ensemble en une transaction. **Bot actif** permet de désactiver le parcours après publication. Les modifications non publiées restent locales ; quitter demande de les abandonner. Une publication concurrente est refusée pour éviter d’écraser les changements d’un autre administrateur.

Le client coche un choix à la fois puis continue. Les étapes protégées cachent leur réponse et leurs sous-choix tant que la personne n’a pas un compte connecté non anonyme. Le parcours initial impose cette connexion avant les informations de paiement VIP, le renouvellement et le dépôt d’un reçu. Les étapes de reçu et de problème d’accès proposent un bouton d’envoi d’image. La sélection seule ne déclenche pas d’accusé de réception : après un envoi réussi, le bot demande d’attendre la vérification humaine. Cet état est également retrouvé dans les messages du chat après réouverture et s’efface lorsqu’un membre de l’équipe répond. Les boutons Retour et Recommencer permettent de naviguer. **Parler à l’équipe** envoie un message utilisateur contenant le parcours choisi dans la conversation existante, visible au dashboard. Les réponses du bot restent dans le panneau d’aide pendant la session ; elles ne sont pas enregistrées comme messages d’un administrateur. Le chat texte, les images et les notes vocales restent accessibles.

La section **Plans** définit le nom, les prix équivalents en HTG et USD, la durée en mois et l’activation de chaque abonnement. Un plan peut être payé par plusieurs moyens : chacun utilise le tarif de sa devise. La section **Informations de paiement** contient le moyen, sa devise, le numéro/compte/e-mail et le bénéficiaire. MonCash, NatCash et Zelle sont préparés mais inactifs dans le parcours initial ; aucune coordonnée ni aucun prix réel n’est prérempli. Les tarifs sont stockés en centimes pour conserver exactement les décimales.

Dans chaque choix, **Moyen de paiement lié** désigne la fiche utilisée par le chatbot. Un même moyen peut servir à plusieurs branches sans recopier ses coordonnées. Une branche liée impose la connexion même si son option de connexion est désactivée. **Publier** enregistre l’arborescence, les plans et les moyens de paiement ensemble. Le plan actif le plus court est recopié dans les anciens champs de prix des moyens de paiement, en HTG ou USD selon le moyen, pour les clients déjà publiés. Deux plans de même durée avec des prix différents dans une devise bloquent la publication. Un moyen inactif n’affiche ni ses coordonnées ni son prix, et propose de contacter l’équipe. Les fiches de paiement sont des informations destinées à être communiquées aux clients ; elles ne doivent pas contenir de mot de passe ou de clé privée. Le bot ne valide pas de paiement et n’active pas d’abonnement.

## Stockage et mise en service

Document : `support_bot/config`, champs `enabled` (bool), `greeting` (texte), `nodes` (liste ordonnée de `{id, parent, label, answer, requiresAuth, requestImage, paymentMethodId}`), `revision` (entier), `paymentMethods` (liste optionnelle de fiches de paiement) et `plans` (liste optionnelle de plans). Les anciennes configurations sans plans restent lisibles et leurs tarifs sont proposés dans l’éditeur. Un parent vide désigne un choix racine. Limites : 80 choix, 6 niveaux, 20 moyens, 30 plans, titre de 100 caractères, réponse de 1500 caractères. Un document absent utilise le parcours initial ; une lecture refusée ou une configuration invalide affiche l’accès au support humain.

Les règles ajoutées autorisent la lecture publique du seul document `config`, y compris pour les visiteurs du chat, et réservent la publication aux administrateurs. Le validateur Dart vérifie la cohérence de l’arbre ; les règles vérifient les droits, les champs principaux, les tailles de liste et la progression de la révision.

La mise en service nécessite la publication des deux applications et du bloc de règles `match /support_bot/{document}`. Les fichiers de règles du dashboard et du client ne sont pas identiques : conserver les autres règles actuellement en production lors de cette publication. Les configurations de déploiement historiques, notamment `voice-only`, ne sont pas modifiées.

Le client actuel ignore le nouveau champ `plans` et continue d’utiliser le prix compatible recopié dans `paymentMethods`. Le dashboard reste responsable de cette projection lors de chaque publication.

## Vérifications

Dashboard : `flutter test --no-pub test/support_bot_test.dart test/support_bot_editor_test.dart test/support_bot_repository_test.dart test/support_inbox_widget_test.dart`

Client : `flutter test --no-pub test/support_bot_test.dart test/support_bot_view_test.dart test/support_chat_view_test.dart`

Dans le dossier `firebase` de chaque application : `firebase emulators:exec --only firestore,auth --project demo-choloto "node tests/support_bot_rules.mjs"`.

Le bouton **Envoyer la preuve de paiement** ouvre désormais le formulaire existant `PaymentRequests`, via le même raccourci que le chat. La soumission crée une demande `payment_requests` avec sa preuve privée et le statut `pending`, traitée par l’écran de validation existant du dashboard. La confirmation du formulaire demande d’attendre la validation humaine. Les demandes de captures d’écran ordinaires utilisent toujours les pièces jointes du chat.

Après validation, le chat observe le statut `approved` de la dernière demande du membre et affiche automatiquement un message de félicitations avec la date de fin VIP. Ce message est également visible dans la carte de la demande validée. L’affichage est dérivé de la demande persistée, sans création répétée de messages ni modification de la transaction de validation existante.
