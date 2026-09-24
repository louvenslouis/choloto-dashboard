# Bot du service client

Le chat client lit `support_bot/config` en temps réel. Le dashboard expose l’éditeur dans **Service client → Bot du service client**. Chaque branche propose les options **Connexion obligatoire** et **Demander une image**. Les choix et les réponses sont libres et commencent en créole haïtien. L’interface des commandes client suit la langue de l’application.

L’éditeur permet de modifier l’accueil, ajouter des choix et des sous-choix, modifier les réponses, réordonner les choix frères et supprimer une branche. **Publier** enregistre l’ensemble en une transaction. **Bot actif** permet de désactiver le parcours après publication. Les modifications non publiées restent locales ; quitter demande de les abandonner. Une publication concurrente est refusée pour éviter d’écraser les changements d’un autre administrateur.

Le client coche un choix à la fois puis continue. Les étapes protégées cachent leur réponse et leurs sous-choix tant que la personne n’a pas un compte connecté non anonyme. Le parcours initial impose cette connexion avant les informations de paiement VIP, le renouvellement et le dépôt d’un reçu. Les étapes de reçu et de problème d’accès proposent un bouton d’envoi d’image. La sélection seule ne déclenche pas d’accusé de réception : après un envoi réussi, le bot demande d’attendre la vérification humaine. Cet état est également retrouvé dans les messages du chat après réouverture et s’efface lorsqu’un membre de l’équipe répond. Les boutons Retour et Recommencer permettent de naviguer. **Parler à l’équipe** envoie un message utilisateur contenant le parcours choisi dans la conversation existante, visible au dashboard. Les réponses du bot restent dans le panneau d’aide pendant la session ; elles ne sont pas enregistrées comme messages d’un administrateur. Le chat texte, les images et les notes vocales restent accessibles.

Les prix et coordonnées de paiement ne sont pas figés dans le parcours initial. L’équipe peut ajouter les informations qu’elle souhaite publier. Le bot ne valide pas de paiement et n’active pas d’abonnement.

## Stockage et mise en service

Document : `support_bot/config`, champs `enabled` (bool), `greeting` (texte), `nodes` (liste ordonnée de `{id, parent, label, answer, requiresAuth, requestImage}`), `revision` (entier). Un parent vide désigne un choix racine. Limites : 80 choix, 6 niveaux, titre de 100 caractères, réponse de 1500 caractères. Un document absent utilise le parcours initial ; une lecture refusée ou une configuration invalide affiche l’accès au support humain.

Les règles ajoutées autorisent la lecture publique du seul document `config`, y compris pour les visiteurs du chat, et réservent la publication aux administrateurs. Le validateur Dart vérifie la cohérence de l’arbre ; les règles vérifient les droits, les champs principaux, les tailles de liste et la progression de la révision.

La mise en service nécessite la publication des deux applications et du bloc de règles `match /support_bot/{document}`. Les fichiers de règles du dashboard et du client ne sont pas identiques : conserver les autres règles actuellement en production lors de cette publication. Les configurations de déploiement historiques, notamment `voice-only`, ne sont pas modifiées.

Les deux applications possèdent la même copie de `support_bot.dart` et `support_bot_repository.dart` ; maintenir leur contrat identique.

## Vérifications

Dashboard : `flutter test --no-pub test/support_bot_test.dart test/support_bot_editor_test.dart test/support_bot_repository_test.dart test/support_inbox_widget_test.dart`

Client : `flutter test --no-pub test/support_bot_test.dart test/support_bot_view_test.dart test/support_chat_view_test.dart`

Dans le dossier `firebase` de chaque application : `firebase emulators:exec --only firestore,auth --project demo-choloto "node tests/support_bot_rules.mjs"`.
