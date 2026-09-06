# CHOLOTO Dashboard

Tableau de bord d’administration CHOLOTO développé avec Flutter.

## Version web

La version de production est publiée sur Cloudflare Pages :

- https://ladministrateur.choloto.com/
- https://choloto-dashboard.pages.dev/

Déploiement manuel depuis la racine du projet :

```bash
flutter build web --release
node tools/fetch_new_york_results.mjs build/web/data/official-new-york-results.json
npx wrangler pages deploy build/web --project-name choloto-dashboard --branch main
```

## Développement local

```bash
flutter pub get
flutter run -d chrome
```

## Google Analytics dans le dashboard

Le panneau **Audience et engagement** interroge directement Google Analytics
Data API avec le compte Google de l’administrateur. L’autorisation demandée est
limitée au scope `analytics.readonly` et le jeton d’accès reste uniquement en
mémoire.

Configuration requise :

1. activer **Google Analytics Data API** dans le projet Google Cloud
   `choloto-6aa5b` ;
2. donner au compte Google administrateur un accès en lecture à la propriété
   GA4 `503828194` ;
3. accepter l’autorisation Analytics lors de la connexion au dashboard ou via
   le bouton **Autoriser Analytics**.

Cette intégration ne déploie aucune Cloud Function et ne nécessite donc pas le
plan Firebase Blaze.
