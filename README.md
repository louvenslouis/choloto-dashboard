# CHOLOTO Dashboard

Site d’administration en **React + TypeScript + Vite**, connecté au projet Firebase existant `choloto-6aa5b`.

## Développement

Node.js 22.12 ou supérieur.

```bash
npm ci
npm run dev
```

Ouvrir l’adresse locale affichée par Vite. La connexion Google utilise les mêmes comptes et règles Firebase que l’ancienne version. Le domaine local doit être autorisé dans Firebase Authentication.

```bash
npm test
npm run build
npm run preview
# Tests navigateur (Google Chrome installé)
npm run test:e2e
```

Le site compilé est dans `dist/`. Aucune installation Flutter n’est nécessaire pour développer, tester ou compiler le site React.

## Hébergement

Les adresses de production restent :

- https://ladministrateur.choloto.com/
- https://choloto-dashboard.pages.dev/

Cloudflare Pages : commande de compilation `npm run build`, dossier de sortie `dist`. La configuration Wrangler pointe désormais vers ce dossier. Les routes SPA et les en-têtes sont dans `public/` ; la fonction `/api/country` reste dans `functions/`.

Pour rafraîchir les copies de résultats officiels avant compilation :

```bash
npm run results
npm run build
npx wrangler pages deploy dist --project-name choloto-dashboard --branch main
```

Le workflow GitHub Pages utilise Node et React, conserve son horaire de rafraîchissement des résultats et compile avec le préfixe `/choloto-dashboard/`. Les données officielles sont téléchargées dans son artefact après compilation.

## Fonctionnement

- Routes existantes conservées : tableau de bord, tirages, prédictions, BINGO, croix, historiques, membres, paiements, support et paramètres.
- Google Authentication ; accès réservé au compte administrateur existant ou au claim Firebase `admin`.
- Schémas Firestore conservés, sans migration des documents ni changement des règles.
- Transactions atomiques pour les paiements et révisions du bot.
- Publication automatique des tirages toutes les dix minutes pendant une session ouverte, après activation dans Tirages. Historique vérifié sur le serveur avant toute publication automatique.
- Export Excel des membres et export CSV des transactions ; reçus imprimables en PDF.
- Support : messages, images JPEG, audio WAV mono à 8 kHz, enregistrement limité à 30 secondes. Nettoyage des conversations ouvertes inactives depuis 15 jours, comme dans la version précédente.
- Thème clair/sombre et mise en page mobile.

Google Analytics utilise la propriété GA4 `503828194` et le scope `analytics.readonly`. Activer Google Analytics Data API et donner au compte administrateur l’accès à la propriété. Le jeton OAuth reste en mémoire.

## Sources

Le code web actif est dans `src/`. Les sources Flutter (`lib/`, `web/`, `android/`, `ios/`, `pubspec.yaml`) restent conservées comme référence de migration, y compris les modifications locales préexistantes. Elles ne font plus partie de la compilation ni du workflow web.

Les tests React utilisent des données simulées et ne modifient pas Firebase en production. Une recette avec une session administrateur est nécessaire pour confirmer les autorisations OAuth et les services Firebase réellement déployés.
