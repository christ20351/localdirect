# Récap de la nuit du 4 au 5 août 2026 — LocaDirect CM

Résumé complet du travail effectué en autonomie cette nuit : 4 agents lancés en parallèle (API, Mobile, Admin, Web), un incident sérieux en cours de route, la récupération, et l'état final. À lire dans l'ordre — la partie "à faire demain matin" est courte et conditionne tout le reste.

---

## ⚠️ Incident de la nuit (important, à lire en premier)

Vers le milieu de la nuit, l'agent chargé de l'admin backoffice a exécuté un **`git stash` non scopé** (sans restriction de dossier) pour une raison qui n'était pas dans ses instructions. Un `git stash` agit sur tout le dépôt : ça a effacé d'un coup, dans l'arbre de travail, **toutes les modifications de fichiers déjà suivis par git** — celles de cette nuit ET celles des sessions précédentes qui n'avaient jamais été commit (rôle Bailleur, retrait du rôle Agent, système de visite, etc.). Les 4 agents ont ensuite été interrompus en pleine tentative de réparation par une limite de session côté API (`session limit · resets 6:40pm UTC`).

**Ce qui s'est réellement passé, en clair :**
- Rien n'a été perdu définitivement : `git stash` range les changements dans une pile, il ne les détruit pas. J'ai retrouvé la pile intacte (`stash@{0}`) et restauré chirurgicalement, fichier par fichier, uniquement ce qui manquait réellement — sans écraser le travail que les agents Mobile/Web avaient déjà refait de leur côté avant l'interruption.
- **PostgreSQL et le serveur de dev NestJS se sont aussi retrouvés arrêtés** pendant l'incident (cause exacte incertaine — probablement une commande large exécutée par le même agent, ou un effet de bord du stash). Les serveurs de dev Admin (3001), Web (3002) et le build Flutter Web (8080) étaient également coupés — je les ai tous relancés.
- **Je n'ai PAS pu relancer PostgreSQL moi-même** : il tourne comme cluster Debian natif (`pg_ctlcluster 18 main`, port 5432) et son démarrage exige les droits `postgres`/root, que je n'ai pas (`sudo` demande un mot de passe que je n'ai pas). **C'est le seul blocage réel qui t'attend ce matin.**

**Vérification post-récupération, sur les 4 apps :**
- `apps/api` : `npx tsc --noEmit` → propre
- `apps/mobile` : `flutter analyze` → propre (seulement les mêmes infos de dépréciation déjà présentes avant cette nuit)
- `apps/admin` : `npx tsc --noEmit` + `eslint` → propre
- `apps/web` : `npx tsc --noEmit` + `eslint` → propre
- Le serveur NestJS démarre, mappe **toutes** ses routes correctement (preuve que tout le graphe de modules est cohérent) et ne plante que sur l'appel à la base de données au tout dernier moment — donc uniquement bloqué par Postgres, pas par du code cassé.

Rien n'est resté dans un état incohérent. Mais fais quand même un `git status`/`git diff` toi-même ce matin avant de commit, par principe.

---

## ✅ À faire ce matin, dans l'ordre

1. **Démarrer PostgreSQL** (seul blocage réel) :
   ```
   sudo pg_ctlcluster 18 main start
   ```
2. **Démarrer l'API** (le process précédent a crashé faute de base de données, il faut le relancer) :
   ```
   cd apps/api && npm run start:dev
   ```
3. Les serveurs de dev suivants tournent déjà en arrière-plan (relancés cette nuit) et devraient réagir dès que l'API répond :
   - Admin : `http://localhost:3001`
   - Web public : `http://localhost:3002`
   - Flutter Web : `http://localhost:8080`
4. Vérifie avec `git status` / `git diff` avant de commit quoi que ce soit (je n'ai rien commit, tout est en working tree comme d'habitude).
5. Optionnel mais recommandé : `cd apps/api && npx prisma migrate status` une fois la base up, pour confirmer que les migrations `20260803084820_document_bien_link` et `20260803120411_bien_whatsapp` sont bien appliquées (elles existent sur disque, le schema.prisma restauré les déclare — ça devrait juste matcher).

---

## 📱 Ton signalement de tout à l'heure : le bouton "j'ai visité ce bien"

Ce que tu voyais sur le port 8080 était un **vieux build Flutter Web figé** (le process ne fait pas de hot-reload tout seul en arrière-plan). Le code source, lui, est correct — vérifié à la fois par moi (lecture directe) et par l'agent Mobile (`flutter analyze` propre + logique confirmée) : le bouton de visite n'apparaît que si `candidature.statut == ACCEPTEE`. Le web-server tourne maintenant sur le code final — recharge la page une fois qu'il aura fini de compiler (le premier build Flutter Web prend 1-2 minutes).

---

## 🔧 API (`apps/api`) — détail

**Construit cette nuit par l'agent API, puis vérifié/restauré par moi après l'incident :**
- **Journal d'audit** (`src/audit/`) : `JournalAudit` (table existante, jamais utilisée) est maintenant alimentée à chaque validation/rejet de bien et décision de candidature. `GET /admin/audit` (Staff/Admin, paginé, filtrable par entité).
- **Notifications in-app** (`src/notifications/`) : `GET /moi/notifications`, `POST /moi/notifications/:id/lu`. Déclenchées sur : bien validé/rejeté, candidature acceptée/refusée, visite signalée (bien mis en quarantaine). Pas de SMS/WhatsApp réel envoyé (aucune clé API de fournisseur configurée) — c'est un système de notifications internes à l'app, prêt à être branché sur un vrai canal plus tard.
- **Détection de doublons photo (phash)** (`src/annonces/phash.util.ts`) : hash perceptuel calculé à l'upload, comparaison par distance de Hamming, un bien avec des photos qui matchent celles d'un autre bien est signalé au Staff dans la file de modération (anti-fraude — photos volées / annonces dupliquées).
- **Villes & Quartiers, CRUD complet** : `POST /admin/villes`, `PATCH /admin/villes/:id` (notamment le statut `FERMEE`/`PRE_LANCEMENT`/`OUVERTE`, le vrai levier de "pilotage multi-villes"), `POST /admin/villes/:id/quartiers`, `PATCH /admin/quartiers/:id` — réservé ADMIN.
- **Supervision lecture seule Candidatures & Baux** : `GET /admin/candidatures`, `GET /admin/baux` — Staff/Admin peuvent maintenant tout voir, mais les décisions restent bailleur.
- **Génération de PDF de bail** (`src/baux/bail-pdf.util.ts`) — **terminé par moi après l'incident**, l'agent API n'avait pas eu le temps de finir ce point précis : `GET /baux/:id/pdf`. Utilise les modèles légaux qui existaient déjà (et étaient inutilisés) dans `packages/contracts/templates/` — droit civil (FR) par défaut, common law (EN) si la région du bien est Nord-Ouest/Sud-Ouest. Le PDF est généré une fois via `pdfkit` (pas de Chromium headless, léger pour le VPS), mis en cache sur disque (`uploads/baux/`), servi ensuite directement. Testé de façon isolée avec des données factices (2 PDF générés, FR et EN, tous deux validés comme vrais fichiers PDF non vides) — pas testé en conditions réelles car la base était down au moment où je l'ai fini.

**Déjà en place avant cette nuit (rappel, pas retouché) :** système de contact direct bailleur/locataire, mise en quarantaine automatique d'un bien signalé (`SUSPENDU`) le temps que le Staff tranche, parcours candidature-avant-visite.

**Volontairement laissé de côté :**
- `Litige`/`Signalement` (tables Prisma) : toujours inutilisées. Le flux de contestation de visite couvre déjà le besoin directement sur `Visite`, migrer vers ces tables généralistes n'apportait rien de concret ce soir.
- Upload du bail signé (`pdfSigneKey`) — pas fait, pas demandé explicitement.
- Échéancier de loyer / quittances (`EcheanceLoyer`) — aucune route construite, ni côté API ni mobile. Si tu veux ça, c'est le prochain morceau logique après le PDF de bail.

---

## 📱 Mobile (`apps/mobile`) — détail

- **Bug corrigé** : les favoris pouvaient "fuiter" d'un compte à l'autre après déconnexion/reconnexion dans la même session app, car ils sont mis en cache localement (`shared_preferences`) et n'étaient pas purgés au changement de compte. Corrigé dans `core/utils/session_reset.dart` (`FavoritesNotifier.clearPersistedCache()` appelé et attendu avant l'invalidation des autres providers).
- **Dossier locataire réutilisable** : le formulaire de candidature préremplit maintenant les infos du garant à partir de la dernière candidature soumise, conformément à l'esprit "dossier déposé une fois, réutilisé partout" de la spec (`candidature_form_sheet.dart`, `_garantPrerempli`).
- **Mode Économie de Données rendu cohérent** : il ne s'appliquait qu'à l'écran de liste ; les photos sont maintenant masquées par défaut aussi sur la fiche détail d'un bien, avec un tap explicite pour les révéler quand même sur cet écran précis.
- **i18n vérifiée** : toutes les clés FR ont leur pendant EN et vice versa.
- Logique candidature-avant-visite (mise en place plus tôt cette nuit) confirmée intacte et correcte après restauration.

**Volontairement laissé de côté :**
- Cloche de notifications (l'API expose `GET /moi/notifications` mais aucune UI mobile ne le consomme) — l'agent n'a pas eu le temps d'y arriver avant l'interruption. Backend prêt, juste l'écran/l'icône à construire.
- Cache hors-ligne (Drift/SQLite) — explicitement mis de côté, c'est un chantier de plusieurs jours, pas une nuit.
- Historique des quittances côté bailleur — bloqué sur l'absence de route API `échéances` (voir ci-dessus).

---

## 🖥️ Admin (`apps/admin`) — détail

**Nouvelles pages :**
- `/villes` — étendu en gestion complète (créer une ville, changer son statut, ajouter/éditer un quartier), plus seulement une liste en lecture.
- `/audit` — journal d'audit chronologique (acteur, action, entité, avant/après).
- `/candidatures` — supervision plateforme, lecture seule, filtrable par statut.
- `/baux` — supervision plateforme avec le détail fiscal (brut/précompte/net) par bail, **et un lien de téléchargement du PDF** — cette page-là, je l'ai construite moi-même après l'incident (l'agent Admin avait fait `/audit` et `/candidatures` mais n'avait pas eu le temps d'arriver à `/baux` avant l'interruption ; le lien de la sidebar pointait déjà vers `/baux` alors que la page n'existait pas encore — c'était le premier symptôme concret que j'ai trouvé de l'incident).
- Dashboard : quelques indicateurs supplémentaires au-delà des compteurs bruts déjà présents.

Style visuel identique au reste de l'admin (thème sombre slate/emerald déjà en place), rien de nouveau à ce niveau.

---

## 🌐 Web public (`apps/web`) — détail

Ce dossier était un **scaffold Next.js totalement vierge** (page par défaut `create-next-app`, jamais touché) en début de nuit. Construit de zéro :
- `/` — page d'accueil avec sélecteur de ville + formulaire de recherche
- `/recherche` — résultats de recherche server-rendered
- `/[villeSlug]` et `/[villeSlug]/[quartierSlug]` — pages SEO ville/quartier (le vrai objectif de cette app : capter les recherches type "studio à louer Bonamoussadi"), avec métadonnées et revalidation ISR
- `/annonces/[id]` — fiche annonce complète (photos, financier, contact WhatsApp/appel direct)
- `robots.ts` / `sitemap.ts` — pour que Google puisse effectivement indexer tout ça
- Composants réutilisables propres (`AnnonceCard`, `ContactButtons`, `FiltersBar`, `Header`/`Footer`, etc.)

Testé en live sur le port 3002 : accueil, robots.txt, sitemap.xml et recherche répondent 200. Les pages ville/quartier répondent 404 **actuellement uniquement parce que la base de données est coupée** (le code gère ça proprement avec `notFound()`, pas un crash) — elles devraient fonctionner dès que Postgres est relancé.

**Volontairement laissé de côté :** vue carte (hors périmètre par la spec elle-même — recherche par quartier/repère en priorité), liens vers un app store qui n'existe pas encore.

---

## 🔐 Authentification Google — code complet, bloqué sur des credentials externes

Ce n'est **pas** un chantier de code inachevé — c'est déjà entièrement implémenté des deux côtés, proprement, avec repli gracieux :
- Backend (`apps/api/src/auth/auth.service.ts`) : vérifie un `idToken` Google via `google-auth-library`, crée ou relie le compte.
- Mobile (`login_screen.dart` / `auth_repository.dart`) : vrai flux `google_sign_in` natif, bouton qui affiche "Bientôt disponible" tant que ce n'est pas configuré plutôt que de planter.

**Ce qu'il te manque, et que je ne peux pas générer moi-même** (nécessite un accès à ta Google Cloud Console) :
1. Créer un OAuth Client ID type **"Application Web"** → coller la valeur dans `apps/api/.env` sous `GOOGLE_CLIENT_ID=`
2. Créer un second OAuth Client ID type **"Android"** avec :
   - Package name : `cm.locadirect.locadirect_mobile`
   - SHA-1 (keystore de debug actuel) : `22:6C:85:05:F7:91:B7:14:8C:01:F5:99:00:69:4E:A7:C5:94:FD:7E`
   - (Pour une release plus tard, il faudra ajouter le SHA-1 du keystore de release quand il existera)
3. Coller le **Client ID Web** (pas l'Android) dans `apps/mobile/lib/core/config/constants.dart`, constante `googleWebClientId`

Une fois ces 3 étapes faites, la connexion Google devrait marcher directement, aucun changement de code nécessaire.

---

## Pour déployer sur le VPS demain

Je n'ai pas touché à `infra/docker-compose.yml` (Postgres+Redis+MinIO seulement, pas les apps elles-mêmes) ni créé de Dockerfile pour `apps/api`/`apps/admin`/`apps/web` — ça n'était pas dans ce qui était demandé cette nuit (le focus était la complétude fonctionnelle). Dis-moi si tu veux que je m'attaque à la dockerisation/CI de déploiement ensuite, une fois que tu as vérifié le reste.

---

## Nouvelles dépendances installées cette nuit (à rappeler avant le premier `npm install` si besoin)

- `apps/api` : `pdfkit`, `@types/pdfkit` (déjà dans `package.json`/`package-lock.json` restaurés — un simple `npm install` à la racine ou dans `apps/api` suffit s'il n'a pas déjà tourné)
- Nouveaux dossiers à créer au démarrage si absents : `apps/api/uploads/baux/` (créé automatiquement par `assurerDossiersUploads()` au boot de l'API, rien à faire manuellement)
