# LocaDirect CM — v2

> Plateforme de location immobilière pour le Cameroun.
> **Le démarcheur n'est pas l'ennemi : c'est le canal de distribution.**

Document technique de démarrage. Il remplace la v1 (générique) par une version tenant compte du marché camerounais réel, et contient de quoi commencer à coder : périmètre MVP, schéma de base de données, API, machines à états, plan de sprints.

---

## 0. Décisions structurantes (ce qui change vs v1)

| # | Décision | Conséquence |
|---|---|---|
| D1 | **Le démarcheur devient un rôle produit à part entière** (`AGENT`), rémunéré à la commission | App agent, mandats, scoring agent, anti-fraude agent |
| D2 | **Multi-villes dès le schéma, déploiement séquencé par ville** | Tables `ville`/`quartier` first-class, feature flags par ville, pas de hardcoding Douala |
| D3 | **Pas de détention de fonds de tiers au MVP** (ni escrow de caution, ni encaissement du loyer) | Évite l'obligation d'agrément BEAC en phase 1. Escrow = phase 3, avec partenaire bancaire/EME |
| D4 | **On monétise la visite et la mise en relation, pas l'abonnement bailleur** | Le bailleur ne paie rien tant qu'il n'a pas loué |
| D5 | **L'« avance » est un objet de première classe**, distinct de la caution | Modèle de données + fonctionnalité de paiement fractionné (phase 2) |
| D6 | **La fraîcheur du stock est une contrainte produit**, pas un détail | Expiration automatique des annonces + reconfirmation obligatoire |
| D7 | **Preuve de propriété par faisceau d'indices**, pas par titre foncier | Sinon on exclut la majorité de l'offre |
| D8 | **Conformité loi n° 2024/017 (données personnelles) dès la conception** | Registre des traitements, DPO, chiffrement des CNI, rétention |
| D9 | **WhatsApp est un canal de premier plan**, pas un fallback | Notifications, onboarding bailleur, support |
| D10 | **Montants en entier XAF**, jamais en flottant | `BIGINT`, pas de décimales (le FCFA n'a pas de subdivision) |

---

## 1. Le problème réel

Ce que la v1 attaquait : la commission d'agence.
Ce qui fait réellement mal au Cameroun :

**Côté locataire**
- Frais de visite payés d'avance (1 000 – 5 000 FCFA) pour des biens **déjà loués, inexistants, ou ne correspondant pas à l'annonce**
- Empilement des démarcheurs : 3 personnes différentes présentent le même bien, chacune prend ses frais
- **L'avance** (2 à 6 mois de loyer) + caution : le vrai mur financier, bien avant la commission
- Annonces mortes sur tous les sites existants (Kerawa, CoinAfrique, groupes Facebook/WhatsApp)

**Côté bailleur**
- Vacance locative longue (il ne sait pas atteindre les locataires)
- Impayés, et procédure d'expulsion judiciaire lente
- Aucune information sur le locataire avant de signer
- Méfiance vis-à-vis de toute traçabilité (fiscalité, voir §9)

**Côté démarcheur**
- Revenus instables, réputation nulle, aucun outil
- C'est pourtant **lui qui détient l'inventaire** et la relation avec les bailleurs non digitalisés

> **Positionnement retenu :** LocaDirect n'élimine pas l'intermédiaire, il le **professionnalise et le rend responsable**. Le locataire paie une visite *garantie* (bien réel, disponible, au prix annoncé) ou il est remboursé. C'est la promesse centrale du produit.

---

## 2. Stratégie multi-villes

L'objectif est national, mais une marketplace se remplit **quartier par quartier**. Densité locale > couverture nationale.

**Architecture : multi-ville dès le jour 1.** Chaque ville a son référentiel de quartiers, ses agents, ses feature flags, son statut d'ouverture. Aucun code spécifique à une ville.

**Déploiement séquencé**

| Vague | Villes | Cible |
|---|---|---|
| V1 | **Douala**, **Yaoundé** | 6-8 quartiers par ville, ~20 agents/ville |
| V2 | **Bafoussam**, **Buea / Limbe**, **Bamenda** | Villes universitaires et anglophones |
| V3 | **Garoua**, **Maroua**, **Ngaoundéré**, **Bertoua** | Grand Nord / Est |
| V4 | **Kribi**, **Dschang**, **Nkongsamba**, **Ebolowa**, **Edéa**, **Kumba** | Villes secondaires |

Une ville n'ouvre au public (`ville.statut = OUVERTE`) que si elle atteint un **seuil de liquidité** : ≥ 150 annonces actives vérifiées et ≥ 10 agents actifs. Avant : `PRE_LANCEMENT` (collecte d'offre uniquement, app en mode « bientôt disponible »).

**Segment prioritaire :** studios, chambres modernes et appartements 2-3 pièces, loyer 25 000 – 200 000 FCFA/mois. C'est le volume. Le haut de gamme / diaspora viendra en phase 4 (produit différent, monétisation différente).

**Bilinguisme obligatoire** (FR/EN) dès le MVP — Buea, Limbe, Bamenda, Kumba.

---

## 3. Le réseau d'agents (ex-démarcheurs)

### 3.1 Statut

Prestataire indépendant, non salarié, sous contrat de partenariat. Il doit :
- passer un KYC complet (CNI vérifiée + selfie + numéro MoMo au même nom)
- signer une charte (pas de frais hors plateforme, pas de fausse annonce, pas de discrimination)
- déposer une **caution de bonne conduite** optionnelle (10 000 FCFA) qui débloque le badge « Agent Garanti »

### 3.2 Ce que l'agent fait

1. **Sourcing** : il démarche les bailleurs et fait entrer le bien sur la plateforme (photos, prix, coordonnées GPS)
2. **Mandat** : il détient un mandat (simple ou exclusif) sur le bien, tracé dans la base
3. **Visite** : il accompagne physiquement le locataire
4. **Closing** : il assiste à la signature

### 3.3 Rémunération

| Événement | Montant indicatif | Part agent | Part plateforme |
|---|---|---|---|
| Visite réalisée et confirmée par le locataire | 2 000 FCFA | 1 400 | 600 |
| Bail signé via la plateforme | 50 % d'un mois de loyer | 60 % | 40 % |
| Bien vérifié ajouté (bonus de démarrage, plafonné) | 1 000 FCFA | 1 000 | — |

Ces chiffres sont des **paramètres en base** (`ville.parametres`), pas des constantes de code : ils seront ajustés ville par ville.

### 3.4 Contrôle qualité

- **Score agent** = f(taux de visites confirmées, taux d'annonces encore disponibles, notes locataires, signalements, délai de réponse)
- Score < seuil → dépriorisation dans le classement, puis suspension
- **Remboursement automatique** des frais de visite si le locataire signale « bien indisponible » ou « ne correspond pas » → débité de l'agent
- Détection de collusion : mêmes numéros récurrents, visites confirmées trop vite, GPS du check-in incohérent

### 3.5 App agent

Application distincte (ou espace dédié) : ajouter un bien en < 5 min, photos guidées, ses mandats, son agenda de visites, ses gains, son retrait MoMo.

---

## 4. Modèle économique

**Ce que personne ne paiera :** un abonnement bailleur. **Ce que tout le monde paie déjà :** les frais de visite.

| Source | Payeur | Montant | Phase |
|---|---|---|---|
| Frais de visite garantie | Locataire | 1 500 – 3 000 FCFA (selon ville) | MVP |
| Frais de mise en relation à la signature | Locataire **et/ou** bailleur | 50 % d'un mois de loyer, partagé | Phase 2 |
| Boost d'annonce | Bailleur / agent | 2 000 – 10 000 FCFA / 15 j | Phase 2 |
| Gestion locative (quittances, relances, tableau de bord) | Bailleur multi-biens | 3-5 % du loyer encaissé | Phase 3 |
| Escrow caution + assurance impayés | Bailleur | à définir avec partenaire | Phase 4 |

**Contraintes à ne pas oublier dans le calcul de marge :**
- Commission Mobile Money **1 à 2,5 %** sur chaque encaissement, à la charge de la plateforme
- Coût d'acquisition d'une annonce vérifiée (temps agent + vérification humaine) : viser < 1 500 FCFA
- Coût de support humain par transaction

### Risque n°1 : la désintermédiation

Bailleur et locataire se rencontrent puis concluent hors plateforme. Réponses produit (pas contractuelles) :
- numéros de téléphone masqués tant que la visite n'est pas payée (proxy d'appel en phase 2)
- la valeur se déplace **après** la signature : quittances légales, historique de paiement portable, attestation fiscale, tableau de bord bailleur
- l'agent est intéressé au closing sur plateforme (il perd sa commission sinon)
- KPI suivi : **taux de désintermédiation estimé** (visites payées sans bail déclaré, sur biens ensuite marqués loués)

---

## 5. Périmètre MVP

### Dans le MVP

- Comptes (locataire / bailleur / agent / staff), OTP SMS + WhatsApp
- Référentiel villes / quartiers / points de repère
- Création de bien par agent **ou** par bailleur, avec workflow de vérification humaine
- Annonce avec loyer, **avance (mois)**, caution (mois), charges, statut compteurs
- Recherche : quartier, budget, type, nombre de pièces, meublé — carte en option (voir §8.4)
- Fiche bien, favoris, alertes
- **Demande de visite + paiement des frais de visite par Mobile Money**
- Check-in GPS de la visite par l'agent + confirmation par le locataire + remboursement automatique si litige
- Messagerie légère + bascule WhatsApp
- Dossier locataire (CNI, garant, justificatif d'activité) partageable au bailleur
- Contrat de bail PDF **généré et téléchargeable**, signé hors ligne, uploadé
- Back-office : modération d'annonces, vérification KYC, gestion des agents, remboursements, litiges
- Bilingue FR/EN

### Hors MVP (assumé)

| Exclu | Pourquoi |
|---|---|
| Escrow / séquestre de caution | Détention de fonds de tiers = agrément BEAC. Phase 3 avec partenaire |
| Encaissement du loyer mensuel | Idem + réticence fiscale du bailleur. Phase 2/3, en option |
| Signature électronique qualifiée | Valeur probante incertaine localement. Bail PDF + signature papier + upload |
| Score de confiance | Aucune donnée au démarrage. On collecte d'abord |
| Visite virtuelle 360° | Coût data prohibitif côté utilisateur |
| Matching IA, estimation automatique de loyer | Nécessite un historique. Phase 3 |
| Assurance loyers impayés | Offre locale quasi inexistante. À sourcer avant de promettre |

---

## 6. Parcours clés (MVP)

**Locataire**
1. Recherche par quartier + budget (sans compte)
2. Compte + OTP au moment de demander une visite
3. Paie les frais de visite (MoMo) → reçoit le créneau + le contact de l'agent
4. Visite → confirme « bien conforme » ou signale → remboursement auto si non conforme
5. Dépose son dossier (CNI, garant, activité)
6. Bailleur accepte → contrat PDF généré → signature physique → upload
7. Statut du bien passé à `LOUE` automatiquement

**Agent**
1. KYC → validé par le staff
2. Ajoute un bien (photos guidées, GPS, prix, avance, caution) + preuve de propriété
3. Vérification staff (< 24 h) → annonce publiée
4. Reçoit les demandes de visite, check-in GPS sur place
5. Suit la candidature jusqu'à la signature
6. Retire ses gains sur MoMo (seuil minimum 5 000 FCFA)

**Bailleur**
1. Inscrit par l'agent (numéro de téléphone) ou en autonomie
2. Valide par OTP qu'il est bien le propriétaire/mandant
3. Voit les candidatures, accepte/refuse
4. Reçoit le bail PDF, les quittances, le rappel du précompte

---

## 7. Modèle de données (PostgreSQL 16 + PostGIS)

Conventions : `snake_case`, PK `uuid` (`gen_random_uuid()`), `created_at`/`updated_at` partout, montants en **`BIGINT` XAF**, suppression logique (`deleted_at`) sur les entités métier.

```sql
CREATE EXTENSION IF NOT EXISTS pgcrypto;
CREATE EXTENSION IF NOT EXISTS postgis;
CREATE EXTENSION IF NOT EXISTS pg_trgm;

-- =========================================================
-- ENUMS
-- =========================================================
CREATE TYPE role_utilisateur   AS ENUM ('LOCATAIRE','BAILLEUR','AGENT','STAFF','ADMIN');
CREATE TYPE statut_kyc         AS ENUM ('NON_SOUMIS','EN_ATTENTE','VALIDE','REJETE','EXPIRE');
CREATE TYPE statut_ville       AS ENUM ('FERMEE','PRE_LANCEMENT','OUVERTE');
CREATE TYPE type_bien          AS ENUM ('CHAMBRE_SIMPLE','CHAMBRE_MODERNE','STUDIO','APPARTEMENT',
                                        'DUPLEX','MAISON','VILLA','BOUTIQUE','BUREAU','TERRAIN');
CREATE TYPE statut_bien        AS ENUM ('BROUILLON','EN_VERIFICATION','DISPONIBLE','RESERVE','LOUE',
                                        'SUSPENDU','EXPIRE','REJETE');
CREATE TYPE type_mandat        AS ENUM ('SIMPLE','EXCLUSIF','PROPRIETAIRE_DIRECT');
CREATE TYPE statut_visite      AS ENUM ('DEMANDEE','PAYEE','PLANIFIEE','CHECK_IN','REALISEE',
                                        'CONFIRMEE','CONTESTEE','ANNULEE','REMBOURSEE','NO_SHOW');
CREATE TYPE statut_candidature AS ENUM ('BROUILLON','SOUMISE','EN_EXAMEN','ACCEPTEE','REFUSEE','RETIREE');
CREATE TYPE statut_bail        AS ENUM ('PROJET','A_SIGNER','ACTIF','PREAVIS','TERMINE','RESILIE','LITIGE');
CREATE TYPE type_paiement      AS ENUM ('FRAIS_VISITE','FRAIS_SERVICE','BOOST','AVANCE','CAUTION',
                                        'LOYER','REVERSEMENT_AGENT','REMBOURSEMENT');
CREATE TYPE statut_paiement    AS ENUM ('INITIE','EN_ATTENTE','REUSSI','ECHOUE','ANNULE','REMBOURSE');
CREATE TYPE methode_paiement   AS ENUM ('MTN_MOMO','ORANGE_MONEY','CARTE','VIREMENT','ESPECES');
CREATE TYPE type_etat_lieux    AS ENUM ('ENTREE','SORTIE');
CREATE TYPE statut_litige      AS ENUM ('OUVERT','EN_INSTRUCTION','RESOLU','REJETE','ESCALADE');
CREATE TYPE langue             AS ENUM ('FR','EN');

-- =========================================================
-- GEOGRAPHIE
-- =========================================================
CREATE TABLE ville (
  id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  nom           text NOT NULL,
  region        text NOT NULL,             -- Littoral, Centre, Ouest, Nord-Ouest...
  slug          text NOT NULL UNIQUE,
  statut        statut_ville NOT NULL DEFAULT 'FERMEE',
  centre        geography(Point,4326),
  parametres    jsonb NOT NULL DEFAULT '{}'::jsonb,  -- frais_visite, commissions, seuils
  created_at    timestamptz NOT NULL DEFAULT now(),
  updated_at    timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE quartier (
  id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  ville_id      uuid NOT NULL REFERENCES ville(id) ON DELETE CASCADE,
  nom           text NOT NULL,
  slug          text NOT NULL,
  aliases       text[] NOT NULL DEFAULT '{}',   -- "Bonamoussadi", "Bona", orthographes locales
  centre        geography(Point,4326),
  contour       geography(Polygon,4326),
  actif         boolean NOT NULL DEFAULT true,
  UNIQUE (ville_id, slug)
);

-- Repérage réel : il n'y a pas d'adresses, on utilise des points de repère
CREATE TABLE point_repere (
  id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  quartier_id   uuid NOT NULL REFERENCES quartier(id) ON DELETE CASCADE,
  nom           text NOT NULL,            -- "Carrefour Kotto", "Station Total Makepe"
  position      geography(Point,4326) NOT NULL
);

-- =========================================================
-- UTILISATEURS
-- =========================================================
CREATE TABLE utilisateur (
  id                 uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  telephone          text NOT NULL UNIQUE,        -- E.164, ex +2376XXXXXXXX
  telephone_verifie  boolean NOT NULL DEFAULT false,
  email              text UNIQUE,
  nom_complet        text,
  photo_url          text,
  roles              role_utilisateur[] NOT NULL DEFAULT '{LOCATAIRE}',
  langue             langue NOT NULL DEFAULT 'FR',
  ville_id           uuid REFERENCES ville(id),
  statut_kyc         statut_kyc NOT NULL DEFAULT 'NON_SOUMIS',
  mot_de_passe_hash  text,
  whatsapp_optin     boolean NOT NULL DEFAULT false,
  derniere_activite  timestamptz,
  bloque             boolean NOT NULL DEFAULT false,
  motif_blocage      text,
  created_at         timestamptz NOT NULL DEFAULT now(),
  updated_at         timestamptz NOT NULL DEFAULT now(),
  deleted_at         timestamptz
);
CREATE INDEX ON utilisateur USING gin (roles);

-- Documents d'identité : DONNEES SENSIBLES (loi 2024/017)
-- Stockage chiffré, bucket privé, URL signée courte, purge programmée.
CREATE TABLE document_verification (
  id             uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  utilisateur_id uuid NOT NULL REFERENCES utilisateur(id) ON DELETE CASCADE,
  type           text NOT NULL,     -- CNI_RECTO, CNI_VERSO, SELFIE, PASSEPORT,
                                    -- FACTURE_ENEO, FACTURE_CAMWATER, ACTE_VENTE,
                                    -- TITRE_FONCIER, ATTESTATION_CHEFFERIE, ATTESTATION_EMPLOYEUR
  storage_key    text NOT NULL,
  hash_sha256    text NOT NULL,
  statut         statut_kyc NOT NULL DEFAULT 'EN_ATTENTE',
  motif_rejet    text,
  verifie_par    uuid REFERENCES utilisateur(id),
  verifie_le     timestamptz,
  purge_le       date,              -- rétention
  created_at     timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE agent (
  id                 uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  utilisateur_id     uuid NOT NULL UNIQUE REFERENCES utilisateur(id) ON DELETE CASCADE,
  code_agent         text NOT NULL UNIQUE,        -- DLA-0042
  ville_id           uuid NOT NULL REFERENCES ville(id),
  quartiers_couverts uuid[] NOT NULL DEFAULT '{}',
  numero_momo        text NOT NULL,
  caution_deposee    bigint NOT NULL DEFAULT 0,
  score              numeric(4,2) NOT NULL DEFAULT 50.00,
  nb_visites         int NOT NULL DEFAULT 0,
  nb_visites_ok      int NOT NULL DEFAULT 0,
  nb_baux            int NOT NULL DEFAULT 0,
  suspendu           boolean NOT NULL DEFAULT false,
  charte_signee_le   timestamptz,
  created_at         timestamptz NOT NULL DEFAULT now()
);

-- =========================================================
-- BIENS & ANNONCES
-- =========================================================
CREATE TABLE bien (
  id                uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  reference         text NOT NULL UNIQUE,          -- DLA-BM-00123
  bailleur_id       uuid REFERENCES utilisateur(id),  -- peut être NULL au départ (saisi par l'agent)
  bailleur_tel      text,                          -- avant que le bailleur ait un compte
  cree_par_id       uuid NOT NULL REFERENCES utilisateur(id),
  ville_id          uuid NOT NULL REFERENCES ville(id),
  quartier_id       uuid NOT NULL REFERENCES quartier(id),
  point_repere_id   uuid REFERENCES point_repere(id),
  indication_acces  text,                          -- "après la pharmacie, portail vert"
  position          geography(Point,4326),
  position_floue    geography(Point,4326),         -- position publique (rayon ~200m)
  type              type_bien NOT NULL,
  nb_pieces         int,
  nb_chambres       int,
  nb_douches        int,
  surface_m2        int,
  meuble            boolean NOT NULL DEFAULT false,
  etage             int,
  equipements       text[] NOT NULL DEFAULT '{}',  -- EAU_COURANTE, GROUPE_ELECTROGENE, PARKING,
                                                   -- CLOTURE, GARDIEN, CLIMATISATION, CARRELAGE
  compteur_electricite text,                       -- INDIVIDUEL | COMMUN | FORFAIT | AUCUN
  compteur_eau         text,                       -- INDIVIDUEL | COMMUN | FORAGE | PUITS
  statut            statut_bien NOT NULL DEFAULT 'BROUILLON',
  motif_rejet       text,
  verifie_par_id    uuid REFERENCES utilisateur(id),
  verifie_le        timestamptz,
  created_at        timestamptz NOT NULL DEFAULT now(),
  updated_at        timestamptz NOT NULL DEFAULT now(),
  deleted_at        timestamptz
);
CREATE INDEX ON bien (ville_id, quartier_id, statut);
CREATE INDEX ON bien USING gist (position_floue);

CREATE TABLE mandat (
  id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  bien_id       uuid NOT NULL REFERENCES bien(id) ON DELETE CASCADE,
  agent_id      uuid REFERENCES agent(id),
  type          type_mandat NOT NULL DEFAULT 'SIMPLE',
  taux_commission numeric(5,2),               -- % du premier mois
  debut         date NOT NULL DEFAULT CURRENT_DATE,
  fin           date,
  actif         boolean NOT NULL DEFAULT true
);
CREATE UNIQUE INDEX ON mandat (bien_id) WHERE type = 'EXCLUSIF' AND actif;

CREATE TABLE annonce (
  id                  uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  bien_id             uuid NOT NULL REFERENCES bien(id) ON DELETE CASCADE,
  titre               text NOT NULL,
  description         text,
  loyer_mensuel       bigint NOT NULL,            -- XAF
  charges_mensuelles  bigint NOT NULL DEFAULT 0,
  charges_incluses    boolean NOT NULL DEFAULT false,
  avance_mois         int NOT NULL DEFAULT 2,     -- SPECIFIQUE CM : mois de loyer payés d'avance
  caution_mois        int NOT NULL DEFAULT 1,
  negociable          boolean NOT NULL DEFAULT false,
  disponible_le       date,
  publiee_le          timestamptz,
  expire_le           timestamptz,                -- publiee_le + 30j
  confirmee_le        timestamptz,                -- dernière reconfirmation de disponibilité
  boost_jusqu_a       timestamptz,
  nb_vues             int NOT NULL DEFAULT 0,
  nb_demandes_visite  int NOT NULL DEFAULT 0,
  recherche_tsv       tsvector,
  created_at          timestamptz NOT NULL DEFAULT now(),
  updated_at          timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX ON annonce (loyer_mensuel);
CREATE INDEX ON annonce USING gin (recherche_tsv);

CREATE TABLE media (
  id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  bien_id       uuid NOT NULL REFERENCES bien(id) ON DELETE CASCADE,
  storage_key   text NOT NULL,
  ordre         int NOT NULL DEFAULT 0,
  largeur       int, hauteur int, taille_octets int,
  phash         text,                 -- hash perceptuel : détection de photos volées / doublons
  piece         text,                 -- SALON, CHAMBRE, DOUCHE, CUISINE, EXTERIEUR
  created_at    timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX ON media (phash);

CREATE TABLE favori (
  utilisateur_id uuid NOT NULL REFERENCES utilisateur(id) ON DELETE CASCADE,
  annonce_id     uuid NOT NULL REFERENCES annonce(id) ON DELETE CASCADE,
  created_at     timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (utilisateur_id, annonce_id)
);

CREATE TABLE alerte_recherche (
  id             uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  utilisateur_id uuid NOT NULL REFERENCES utilisateur(id) ON DELETE CASCADE,
  criteres       jsonb NOT NULL,
  canal          text NOT NULL DEFAULT 'PUSH',   -- PUSH | SMS | WHATSAPP
  actif          boolean NOT NULL DEFAULT true,
  derniere_notif timestamptz
);

-- =========================================================
-- VISITES  (coeur du MVP)
-- =========================================================
CREATE TABLE visite (
  id                uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  annonce_id        uuid NOT NULL REFERENCES annonce(id),
  locataire_id      uuid NOT NULL REFERENCES utilisateur(id),
  agent_id          uuid REFERENCES agent(id),
  statut            statut_visite NOT NULL DEFAULT 'DEMANDEE',
  creneau_debut     timestamptz,
  creneau_fin       timestamptz,
  frais             bigint NOT NULL,
  paiement_id       uuid,
  code_confirmation text,                      -- 4 chiffres donnés par le locataire à l'agent
  checkin_position  geography(Point,4326),
  checkin_le        timestamptz,
  confirmee_le      timestamptz,
  motif_contestation text,                     -- INDISPONIBLE | NON_CONFORME | AGENT_ABSENT | PRIX_DIFFERENT
  rembourse_le      timestamptz,
  created_at        timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX ON visite (agent_id, statut);
CREATE INDEX ON visite (locataire_id, created_at DESC);

-- =========================================================
-- CANDIDATURE & BAIL
-- =========================================================
CREATE TABLE garant (
  id             uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  locataire_id   uuid NOT NULL REFERENCES utilisateur(id) ON DELETE CASCADE,
  nom_complet    text NOT NULL,
  telephone      text NOT NULL,
  profession     text,
  lien           text,                    -- PARENT, EMPLOYEUR, AMI
  cni_document_id uuid REFERENCES document_verification(id),
  verifie        boolean NOT NULL DEFAULT false
);

CREATE TABLE candidature (
  id                  uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  annonce_id          uuid NOT NULL REFERENCES annonce(id),
  locataire_id        uuid NOT NULL REFERENCES utilisateur(id),
  visite_id           uuid REFERENCES visite(id),
  statut              statut_candidature NOT NULL DEFAULT 'BROUILLON',
  revenu_declare      bigint,
  source_revenu       text,               -- SALAIRE, COMMERCE, ARTISANAT, ETUDIANT, DIASPORA
  garant_id           uuid REFERENCES garant(id),
  nb_occupants        int,
  message             text,
  motif_refus         text,
  soumise_le          timestamptz,
  decidee_le          timestamptz,
  UNIQUE (annonce_id, locataire_id)
);

CREATE TABLE bail (
  id                 uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  reference          text NOT NULL UNIQUE,
  bien_id            uuid NOT NULL REFERENCES bien(id),
  bailleur_id        uuid NOT NULL REFERENCES utilisateur(id),
  locataire_id       uuid NOT NULL REFERENCES utilisateur(id),
  agent_id           uuid REFERENCES agent(id),
  candidature_id     uuid REFERENCES candidature(id),
  statut             statut_bail NOT NULL DEFAULT 'PROJET',
  date_debut         date NOT NULL,
  date_fin           date,
  duree_mois         int,
  loyer_mensuel      bigint NOT NULL,
  charges_mensuelles bigint NOT NULL DEFAULT 0,
  jour_echeance      int NOT NULL DEFAULT 5,
  avance_mois        int NOT NULL DEFAULT 2,
  avance_montant     bigint NOT NULL DEFAULT 0,
  caution_montant    bigint NOT NULL DEFAULT 0,
  caution_detenue_par text NOT NULL DEFAULT 'BAILLEUR',  -- BAILLEUR | PLATEFORME (phase 3)
  precompte_applicable boolean NOT NULL DEFAULT true,     -- retenue à la source sur loyer
  taux_precompte     numeric(5,2) NOT NULL DEFAULT 10.00,
  pdf_storage_key    text,
  pdf_signe_key      text,
  signe_le           timestamptz,
  created_at         timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE echeance_loyer (
  id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  bail_id       uuid NOT NULL REFERENCES bail(id) ON DELETE CASCADE,
  periode       date NOT NULL,               -- 1er du mois concerné
  montant_du    bigint NOT NULL,
  montant_paye  bigint NOT NULL DEFAULT 0,
  date_limite   date NOT NULL,
  quittance_key text,
  UNIQUE (bail_id, periode)
);

-- =========================================================
-- PAIEMENTS  (journal + transactions PSP séparés)
-- =========================================================
CREATE TABLE paiement (
  id                uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  reference         text NOT NULL UNIQUE,
  payeur_id         uuid REFERENCES utilisateur(id),
  beneficiaire_id   uuid REFERENCES utilisateur(id),
  type              type_paiement NOT NULL,
  statut            statut_paiement NOT NULL DEFAULT 'INITIE',
  methode           methode_paiement,
  montant           bigint NOT NULL,
  frais_psp         bigint NOT NULL DEFAULT 0,
  devise            char(3) NOT NULL DEFAULT 'XAF',
  visite_id         uuid REFERENCES visite(id),
  bail_id           uuid REFERENCES bail(id),
  echeance_id       uuid REFERENCES echeance_loyer(id),
  annonce_id        uuid REFERENCES annonce(id),
  idempotency_key   text UNIQUE NOT NULL,
  created_at        timestamptz NOT NULL DEFAULT now(),
  regle_le          timestamptz
);

CREATE TABLE transaction_psp (
  id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  paiement_id     uuid NOT NULL REFERENCES paiement(id) ON DELETE CASCADE,
  psp             text NOT NULL,          -- CAMPAY | FAPSHI | MONETBIL | NOTCHPAY | ...
  psp_reference   text,
  operateur       text,                   -- MTN | ORANGE
  numero          text,
  requete         jsonb,
  reponse         jsonb,
  webhook_recu_le timestamptz,
  statut_brut     text,
  created_at      timestamptz NOT NULL DEFAULT now()
);
CREATE UNIQUE INDEX ON transaction_psp (psp, psp_reference) WHERE psp_reference IS NOT NULL;

-- Grand livre : toute somme entrante/sortante laisse deux écritures
CREATE TABLE ecriture (
  id            bigserial PRIMARY KEY,
  paiement_id   uuid REFERENCES paiement(id),
  compte        text NOT NULL,     -- PLATEFORME, AGENT:<id>, BAILLEUR:<id>, PSP:<nom>, CLIENT:<id>
  sens          char(1) NOT NULL CHECK (sens IN ('D','C')),
  montant       bigint NOT NULL CHECK (montant > 0),
  libelle       text,
  created_at    timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX ON ecriture (compte, created_at);

CREATE TABLE retrait_agent (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  agent_id    uuid NOT NULL REFERENCES agent(id),
  montant     bigint NOT NULL,
  numero_momo text NOT NULL,
  statut      statut_paiement NOT NULL DEFAULT 'INITIE',
  paiement_id uuid REFERENCES paiement(id),
  created_at  timestamptz NOT NULL DEFAULT now()
);

-- =========================================================
-- ETAT DES LIEUX / LITIGES / CONFIANCE
-- =========================================================
CREATE TABLE etat_lieux (
  id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  bail_id       uuid NOT NULL REFERENCES bail(id) ON DELETE CASCADE,
  type          type_etat_lieux NOT NULL,
  realise_le    timestamptz,
  position      geography(Point,4326),
  signe_bailleur boolean NOT NULL DEFAULT false,
  signe_locataire boolean NOT NULL DEFAULT false,
  pdf_key       text
);

CREATE TABLE etat_lieux_item (
  id             uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  etat_lieux_id  uuid NOT NULL REFERENCES etat_lieux(id) ON DELETE CASCADE,
  piece          text NOT NULL,
  element        text NOT NULL,          -- MUR, SOL, PORTE, ROBINETTERIE, PRISE
  etat           text NOT NULL,          -- NEUF, BON, USAGE, MAUVAIS
  commentaire    text,
  media_keys     text[] NOT NULL DEFAULT '{}'
);

CREATE TABLE avis (
  id           uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  auteur_id    uuid NOT NULL REFERENCES utilisateur(id),
  cible_id     uuid NOT NULL REFERENCES utilisateur(id),
  bail_id      uuid REFERENCES bail(id),
  visite_id    uuid REFERENCES visite(id),
  note         int NOT NULL CHECK (note BETWEEN 1 AND 5),
  commentaire  text,
  publie       boolean NOT NULL DEFAULT false,   -- double aveugle : publié quand les 2 ont noté
  created_at   timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE signalement (
  id           uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  auteur_id    uuid REFERENCES utilisateur(id),
  cible_type   text NOT NULL,        -- ANNONCE | UTILISATEUR | AGENT | MESSAGE
  cible_id     uuid NOT NULL,
  motif        text NOT NULL,        -- ARNAQUE | DOUBLON | PRIX_ABERRANT | DEJA_LOUE | CONTENU
  details      text,
  traite_le    timestamptz,
  traite_par   uuid REFERENCES utilisateur(id),
  created_at   timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE litige (
  id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  bail_id       uuid REFERENCES bail(id),
  visite_id     uuid REFERENCES visite(id),
  ouvert_par_id uuid NOT NULL REFERENCES utilisateur(id),
  categorie     text NOT NULL,       -- CAUTION | IMPAYE | ETAT_BIEN | FRAIS_VISITE | AGENT
  statut        statut_litige NOT NULL DEFAULT 'OUVERT',
  montant_conteste bigint,
  decision      text,
  assigne_a     uuid REFERENCES utilisateur(id),
  created_at    timestamptz NOT NULL DEFAULT now(),
  clos_le       timestamptz
);

-- =========================================================
-- COMMUNICATION & SYSTEME
-- =========================================================
CREATE TABLE conversation (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  annonce_id  uuid REFERENCES annonce(id),
  bail_id     uuid REFERENCES bail(id),
  created_at  timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE participant_conversation (
  conversation_id uuid NOT NULL REFERENCES conversation(id) ON DELETE CASCADE,
  utilisateur_id  uuid NOT NULL REFERENCES utilisateur(id) ON DELETE CASCADE,
  lu_jusqu_a      timestamptz,
  PRIMARY KEY (conversation_id, utilisateur_id)
);

CREATE TABLE message (
  id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  conversation_id uuid NOT NULL REFERENCES conversation(id) ON DELETE CASCADE,
  expediteur_id   uuid NOT NULL REFERENCES utilisateur(id),
  contenu         text NOT NULL,
  media_key       text,
  masque          boolean NOT NULL DEFAULT false,   -- anti-fuite de numéro
  created_at      timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE notification (
  id             uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  utilisateur_id uuid NOT NULL REFERENCES utilisateur(id) ON DELETE CASCADE,
  canal          text NOT NULL,       -- PUSH | SMS | WHATSAPP | IN_APP
  gabarit        text NOT NULL,
  variables      jsonb NOT NULL DEFAULT '{}'::jsonb,
  envoye_le      timestamptz,
  lu_le          timestamptz,
  erreur         text
);

CREATE TABLE otp (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  telephone   text NOT NULL,
  code_hash   text NOT NULL,
  canal       text NOT NULL DEFAULT 'SMS',
  tentatives  int NOT NULL DEFAULT 0,
  expire_le   timestamptz NOT NULL,
  consomme_le timestamptz,
  created_at  timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX ON otp (telephone, created_at DESC);

CREATE TABLE journal_audit (
  id             bigserial PRIMARY KEY,
  acteur_id      uuid REFERENCES utilisateur(id),
  action         text NOT NULL,
  entite         text NOT NULL,
  entite_id      uuid,
  avant          jsonb,
  apres          jsonb,
  ip             inet,
  created_at     timestamptz NOT NULL DEFAULT now()
);

-- Référentiel de prix par quartier (alimente l'estimation de loyer, phase 3)
CREATE TABLE reference_prix (
  id           uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  quartier_id  uuid NOT NULL REFERENCES quartier(id),
  type         type_bien NOT NULL,
  nb_pieces    int,
  loyer_p25    bigint, loyer_median bigint, loyer_p75 bigint,
  echantillon  int NOT NULL DEFAULT 0,
  calcule_le   timestamptz NOT NULL DEFAULT now(),
  UNIQUE (quartier_id, type, nb_pieces)
);
```

### Règles métier à implémenter en base (triggers / jobs)

- `annonce.expire_le = publiee_le + 30 jours` → job quotidien qui passe le bien en `EXPIRE` et notifie l'agent/bailleur pour reconfirmation
- Un bien en `LOUE` ne peut pas avoir de visite `DEMANDEE` → contrainte applicative + garde-fou SQL
- `visite.statut = CONFIRMEE` → génération automatique des écritures de commission agent
- `visite` contestée sous 24 h et non contredite → remboursement automatique
- `avis.publie` bascule à `true` uniquement quand les deux parties ont noté, ou après 14 jours

---

## 8. API (v1)

REST, JSON, `Authorization: Bearer <JWT>`, versionnée sous `/api/v1`. Pagination par curseur.

### 8.1 Auth
```
POST   /auth/otp/demander          { telephone, canal }        # SMS ou WhatsApp
POST   /auth/otp/verifier          { telephone, code } -> { access, refresh, utilisateur }
POST   /auth/refresh
POST   /auth/profil                # complète nom, langue, ville
GET    /moi
```

### 8.2 Référentiel
```
GET    /villes                     ?statut=OUVERTE
GET    /villes/:slug/quartiers
GET    /quartiers/:id/reperes
```

### 8.3 Recherche & annonces
```
GET    /annonces                   ?ville=douala&quartiers=bonamoussadi,makepe
                                   &loyer_min=&loyer_max=&type=STUDIO&pieces=2
                                   &meuble=true&avance_max=3&tri=recent|prix|pertinence
GET    /annonces/:id
POST   /annonces/:id/vue
POST   /annonces/:id/favori        DELETE /annonces/:id/favori
GET    /moi/favoris
POST   /alertes                    GET/DELETE /alertes/:id
```

### 8.4 Publication (agent / bailleur)
```
POST   /biens                      # brouillon
PATCH  /biens/:id
POST   /biens/:id/medias           # upload direct S3 via URL présignée
POST   /biens/:id/documents        # preuve de propriété
POST   /biens/:id/soumettre        # -> EN_VERIFICATION
POST   /biens/:id/confirmer-dispo  # reconfirmation de fraîcheur
POST   /biens/:id/marquer-loue
GET    /moi/biens
```

### 8.5 Visites
```
POST   /annonces/:id/visites       { creneau_souhaite } -> visite DEMANDEE + paiement à initier
POST   /visites/:id/payer          { methode, numero } -> { paiement_id, statut }
GET    /visites/:id
POST   /visites/:id/checkin        { lat, lng, code_confirmation }   # agent, sur place
POST   /visites/:id/confirmer      # locataire : "bien conforme"
POST   /visites/:id/contester      { motif, details }
POST   /visites/:id/annuler
GET    /moi/visites                GET /agent/visites
```

### 8.6 Candidature & bail
```
POST   /annonces/:id/candidatures
POST   /candidatures/:id/soumettre
POST   /candidatures/:id/decider   { decision, motif }        # bailleur
POST   /candidatures/:id/bail      # génère le projet de bail
GET    /baux/:id                   GET /baux/:id/pdf
POST   /baux/:id/signature         # upload du PDF signé
GET    /baux/:id/echeances
POST   /echeances/:id/quittance
```

### 8.7 Paiements
```
POST   /paiements                  { type, montant, methode, numero, idempotency_key }
GET    /paiements/:id
POST   /webhooks/psp/:psp          # signature vérifiée, idempotent, rejoue-safe
GET    /agent/solde
POST   /agent/retraits             { montant }
```

### 8.8 Back-office
```
GET    /admin/biens?statut=EN_VERIFICATION
POST   /admin/biens/:id/valider | /rejeter
GET    /admin/kyc?statut=EN_ATTENTE
POST   /admin/kyc/:id/valider | /rejeter
GET    /admin/signalements  /admin/litiges  /admin/agents
POST   /admin/remboursements
GET    /admin/metriques?ville=&periode=
```

---

## 9. Architecture technique

### 9.1 Stack

| Couche | Choix | Pourquoi |
|---|---|---|
| Mobile | **Flutter** | Un seul code Android/iOS, APK léger, bon rendu sur Android bas de gamme (cible : Android 8+, < 25 Mo) |
| Back | **NestJS (TypeScript) + Prisma** | Types partagés avec le back-office, écosystème, recrutement |
| Back-office | **Next.js (App Router)** | Modération, KYC, litiges, métriques |
| Site public | Next.js SSR/ISR | SEO : « studio à louer Bonamoussadi » est une requête à fort volume |
| BDD | **PostgreSQL 16 + PostGIS + pg_trgm** | Relationnel, géo, recherche floue sur les noms de quartiers |
| Cache / files | **Redis + BullMQ** | Jobs : notifications, expiration d'annonces, réconciliation PSP |
| Fichiers | S3-compatible (Scaleway / Backblaze / MinIO) | Bucket public (photos) + bucket privé chiffré (CNI) |
| Push | Firebase Cloud Messaging | |
| SMS / WhatsApp | Agrégateur local + WhatsApp Business API | Le SMS local est moins cher via agrégateur camerounais |
| Observabilité | Sentry + Grafana/Loki | |

> **Alternative si l'équipe fait < 3 devs :** Django + DRF. Le `django-admin` fournit gratuitement 80 % du back-office de modération, qui est sinon plusieurs semaines de travail. C'est un arbitrage vitesse-de-lancement contre cohérence de stack — à trancher avant le premier commit.

### 9.2 Paiements Mobile Money

Ne pas intégrer MTN MoMo et Orange Money en direct au démarrage : délais de conventionnement, exigences de conformité, comptes marchands. Passer par un **agrégateur camerounais** (CamPay, Fapshi, Monetbil, Notch Pay, Diool…), puis internaliser quand le volume le justifie.

À concevoir dès le départ :
- **Interface `PaymentProvider`** avec au moins deux implémentations → on doit pouvoir changer de PSP en une variable d'environnement
- **Idempotence obligatoire** sur l'initiation et sur les webhooks
- Machine à états : `INITIE → EN_ATTENTE → REUSSI | ECHOUE`, avec **polling de secours** si le webhook n'arrive pas (fréquent)
- **Réconciliation quotidienne** automatique contre le relevé PSP
- Les frais PSP (1-2,5 %) sont enregistrés dans `paiement.frais_psp` et imputés à la plateforme
- Écritures en partie double dans `ecriture` — sans ça, la commission agent devient impossible à auditer

### 9.3 Réalité réseau et terminaux

- Cible : **Android 8+, 2 Go de RAM, réseau 3G instable, data chère**
- Photos : upload compressé côté client (WebP, max 1600 px, ~150 Ko), 3 tailles générées côté serveur
- **Liste d'annonces en mode texte d'abord**, images en lazy load ; option « économiser les données »
- Cache local (Drift/SQLite) des annonces consultées et des favoris, consultables hors ligne
- File d'attente locale pour les actions agent (ajout de bien, check-in) → synchronisation différée
- Budget : < 500 Ko de data pour une session de recherche typique

### 9.4 Carte

La carte n'est **pas** le mode de recherche principal (coûteuse en data, et le géocodage camerounais est pauvre). Recherche par **quartier + point de repère** en premier, carte en vue secondaire. Utiliser MapLibre + tuiles OpenStreetMap plutôt que Google Maps (coût).

**Position floue publique** : ne jamais exposer la position exacte d'un bien disponible avant paiement de la visite (`position_floue`, décalage aléatoire ~200 m).

### 9.5 Repo

```
locadirect/
├─ apps/
│  ├─ api/            # NestJS
│  ├─ admin/          # Next.js back-office
│  ├─ web/            # Next.js site public (SEO)
│  └─ mobile/         # Flutter (locataire + bailleur + agent)
├─ packages/
│  ├─ shared-types/
│  ├─ contracts/      # gabarits de bail (FR/EN), quittances
│  └─ config/
├─ infra/             # docker-compose, migrations, seeds villes/quartiers
└─ docs/
```

### 9.6 Variables d'environnement (extrait)

```
DATABASE_URL=
REDIS_URL=
JWT_SECRET=  JWT_REFRESH_SECRET=
S3_ENDPOINT=  S3_BUCKET_PUBLIC=  S3_BUCKET_PRIVE=  S3_KEY=  S3_SECRET=
KYC_ENCRYPTION_KEY=            # chiffrement au repos des documents d'identité
PSP_PROVIDER=campay            # campay | fapshi | monetbil
PSP_API_KEY=  PSP_SECRET=  PSP_WEBHOOK_SECRET=
SMS_PROVIDER=  SMS_API_KEY=
WHATSAPP_TOKEN=  WHATSAPP_PHONE_ID=
FCM_SERVER_KEY=
FEATURE_ESCROW=false
FEATURE_LOYER_EN_LIGNE=false
```

---

## 10. Fiscalité, juridique, conformité

À traiter comme des fonctionnalités, pas comme des mentions légales.

**Précompte sur loyer.** Retenu à la source par le locataire et reversé au plus tard le 15 du mois suivant ; le taux a été ramené à **10 %** en 2026 (contre 15 % auparavant). L'app doit : afficher clairement loyer brut / précompte / net bailleur, produire un récapitulatif annuel, et rappeler l'échéance. **Vérifier le taux et les cas d'exemption avec un fiscaliste avant d'afficher des chiffres à l'utilisateur.**

**Enregistrement du bail.** Droits d'enregistrement + timbre. Prévoir un champ « bail enregistré » et, en phase 2, un service payant d'accompagnement à l'enregistrement — c'est un vrai service à valeur ajoutée.

**Réticence fiscale du bailleur.** C'est le frein d'adoption n°1 une fois le produit compris. Positionnement à tenir : *« votre conformité gérée, vos justificatifs prêts »*, et ne pas rendre l'encaissement du loyer en ligne obligatoire au MVP.

**Données personnelles — loi n° 2024/017 du 23 décembre 2024**, autorité de contrôle (APDP), mise en conformité échue depuis **juin 2026**. À implémenter :
- registre des traitements, politique de confidentialité FR/EN, DPO désigné
- consentement explicite et journalisé pour les documents d'identité (données sensibles)
- chiffrement au repos + URL signées courtes + purge programmée (`document_verification.purge_le`)
- procédure de notification de violation, droit d'accès/suppression exposé dans l'app

**Paiements.** Tant que la plateforme ne détient pas de fonds pour le compte de tiers, elle reste cliente d'un agrégateur agréé. Dès qu'on parle d'escrow de caution ou d'encaissement de loyer reversé, le cadre BEAC/COBAC s'applique (statuts d'établissement de paiement, réforme en cours sur les agrégateurs et initiateurs de paiement) → **conseil juridique obligatoire avant la phase 3**.

**Bail.** Gabarits séparés pour le droit civil (zones francophones) et la common law (Nord-Ouest, Sud-Ouest). Faire relire les deux par un avocat camerounais avant la mise en production.

---

## 11. Confiance et anti-fraude

| Risque | Contre-mesure |
|---|---|
| Annonce fictive | Vérification humaine avant publication + preuve de propriété + photos géolocalisées prises dans l'app |
| Photos volées sur Internet ou d'un autre site | Hash perceptuel (`media.phash`), rejet des doublons connus |
| Bien déjà loué mais annonce vivante | Expiration à 30 j + reconfirmation obligatoire + signalement locataire + pénalité agent |
| Faux agent | Code agent, badge vérifié, QR code affichable, check-in GPS |
| Frais de visite hors plateforme | Frais payés dans l'app avant divulgation du contact ; l'agent est payé après confirmation |
| Prix aberrant | Alerte automatique si le loyer s'écarte de ±60 % de la médiane du quartier (`reference_prix`) |
| Multi-comptes | Unicité du numéro + empreinte d'appareil + limite de vitesse |
| Collusion agent-locataire | Confirmations trop rapides, GPS incohérent, mêmes paires récurrentes |

**Preuve de propriété — faisceau d'indices accepté** (au moins 2 sur 4) :
1. Facture ENEO ou Camwater récente au nom du bailleur
2. CNI du bailleur + selfie
3. Acte de vente sous seing privé, certificat/titre foncier, ou attestation de chefferie
4. Ancien bail ou quittance émise par le bailleur

Exiger le titre foncier seul reviendrait à exclure la majorité du parc locatif.

---

## 12. Opérations (à budgéter)

Ce n'est pas de la tech, mais ça détermine la viabilité :

- **Modérateurs** : ~1 personne pour 300 biens à vérifier / semaine
- **Support téléphone + WhatsApp** : ici les gens appellent. Prévoir une ligne, des horaires, des scripts
- **Responsable réseau agents par ville** : recrutement, formation, sanctions
- **Instruction des litiges** : SLA 72 h, base de décisions écrite
- Coût opérationnel cible par bien vérifié : **< 1 500 FCFA**

---

## 13. Roadmap (sprints de 2 semaines)

**Phase 1 — MVP Douala (S1 → S10, ~5 mois)**

| Sprint | Contenu |
|---|---|
| S1 | Socle : monorepo, CI, Postgres+PostGIS, auth OTP, schéma utilisateurs/géo, seeds Douala (quartiers + repères) |
| S2 | Biens & annonces : CRUD, upload photos, workflow de vérification, back-office de modération |
| S3 | Recherche + fiche bien + favoris + alertes ; app mobile locataire (écrans 1-5) |
| S4 | App agent : ajout de bien guidé, mandats, mes annonces, mode hors ligne |
| S5 | Paiements : intégration agrégateur, machine à états, webhooks, idempotence, écritures |
| S6 | Visites : demande, paiement, planification, check-in GPS, confirmation, contestation, remboursement |
| S7 | Candidature + dossier locataire + garant ; messagerie + notifications (push/SMS/WhatsApp) |
| S8 | Génération du bail PDF (FR/EN), quittances, échéancier, calcul du précompte |
| S9 | Anti-fraude (phash, prix aberrants, score agent), litiges, métriques back-office, conformité APDP |
| S10 | Durcissement, tests de charge, mode faible connectivité, bêta fermée 30 agents / 200 biens |

**Phase 2 — Yaoundé + monétisation de la signature (S11 → S16)**
Frais de service à la signature, boost d'annonces, paiement fractionné de l'avance, service d'enregistrement du bail, tableau de bord bailleur.

**Phase 3 — Gestion locative & escrow (S17 → S24)**
Encaissement du loyer en ligne (optionnel), quittances automatiques, relances, état des lieux digital, escrow de la caution **avec partenaire bancaire/EME**, score de confiance.

**Phase 4 — Échelle nationale**
Vagues V2/V3/V4, estimation automatique de loyer, matching, assurance impayés, offre diaspora.

---

## 14. KPIs

**Liquidité (les seuls qui comptent au début)**
- Annonces actives vérifiées par quartier
- **Taux de fraîcheur** : % d'annonces confirmées disponibles < 7 j
- Délai médian publication → premier contact
- Délai médian publication → bien loué

**Qualité de l'expérience**
- **Taux de visites confirmées conformes** (cible > 85 %) ← indicateur central de la promesse produit
- Taux de remboursement de frais de visite (cible < 10 %)
- Visites nécessaires avant signature

**Économie**
- Coût d'acquisition par annonce vérifiée
- Revenu par bien loué
- Marge nette après frais PSP et coûts agent
- **Taux de désintermédiation estimé**

**Réseau**
- Agents actifs / ville, biens par agent actif, rétention agent à 3 mois

---

## 15. Risques majeurs

| Risque | Gravité | Atténuation |
|---|---|---|
| Les bailleurs refusent la traçabilité fiscale | Élevée | Ne pas imposer l'encaissement en ligne ; vendre la conformité comme service |
| Désintermédiation après la visite | Élevée | Contact masqué, valeur post-signature, intéressement agent |
| Les agents contournent la plateforme | Élevée | Commission attractive, exclusivité douce, score, caution de bonne conduite |
| Escrow bloqué par la réglementation BEAC | Moyenne | Hors MVP, partenaire agréé en phase 3 |
| Concurrence gratuite (groupes WhatsApp/Facebook) | Moyenne | La garantie de visite est la seule chose qu'ils ne peuvent pas offrir |
| Coût du réseau terrain plus élevé que prévu | Moyenne | Piloter le CAC par annonce vérifiée dès S4 |
| Fiabilité des agrégateurs de paiement | Moyenne | Deux PSP intégrés dès le départ, bascule par variable d'environnement |

---

## Annexe A — Premiers tickets

1. `infra` : docker-compose (Postgres+PostGIS, Redis, MinIO) + migration initiale du schéma §7
2. `data` : seed `ville`/`quartier`/`point_repere` pour Douala et Yaoundé (~40 quartiers, aliases inclus)
3. `api` : auth OTP (demander/vérifier), rate limiting, JWT + refresh
4. `api` : CRUD `bien` + upload S3 présigné + machine à états `statut_bien`
5. `admin` : file de modération (liste, détail, valider/rejeter avec motif)
6. `api` : recherche d'annonces avec filtres §8.3 + tri + pagination curseur
7. `mobile` : écran recherche + fiche bien, mode économie de données
8. `api` : interface `PaymentProvider` + implémentation agrégateur #1 + webhook idempotent
9. `api` : cycle de vie complet de la visite (§8.5) avec check-in GPS
10. `jobs` : expiration d'annonces à 30 j + relance de reconfirmation (WhatsApp/SMS)

## Annexe B — À valider avant de coder

- [ ] Taux et modalités du précompte sur loyer confirmés par un fiscaliste
- [ ] Gabarits de bail relus par un avocat (droit civil **et** common law)
- [ ] Agrégateur de paiement retenu : tarifs réels, délais de règlement, qualité des webhooks
- [ ] Conditions de la promesse « visite garantie remboursée » (qui supporte le coût, plafond mensuel)
- [ ] Grille de commission agent testée sur 5 démarcheurs réels avant de la coder
- [ ] Registre des traitements et désignation du DPO (loi n° 2024/017)
