-- =========================================================
-- LocaDirect CM v2 — Migration Initiale
-- Base de données : PostgreSQL 16 + PostGIS + pg_trgm
-- =========================================================

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
CREATE INDEX idx_utilisateur_roles ON utilisateur USING gin (roles);

CREATE TABLE document_verification (
  id             uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  utilisateur_id uuid NOT NULL REFERENCES utilisateur(id) ON DELETE CASCADE,
  type           text NOT NULL,     -- CNI_RECTO, CNI_VERSO, SELFIE, PASSEPORT
  storage_key    text NOT NULL,
  hash_sha256    text NOT NULL,
  statut         statut_kyc NOT NULL DEFAULT 'EN_ATTENTE',
  motif_rejet    text,
  verifie_par    uuid REFERENCES utilisateur(id),
  verifie_le     timestamptz,
  purge_le       date,
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
  bailleur_id       uuid REFERENCES utilisateur(id),
  bailleur_tel      text,
  cree_par_id       uuid NOT NULL REFERENCES utilisateur(id),
  ville_id          uuid NOT NULL REFERENCES ville(id),
  quartier_id       uuid NOT NULL REFERENCES quartier(id),
  point_repere_id   uuid REFERENCES point_repere(id),
  indication_acces  text,
  position          geography(Point,4326),
  position_floue    geography(Point,4326),         -- position publique (rayon ~200m)
  type              type_bien NOT NULL,
  nb_pieces         int,
  nb_chambres       int,
  nb_douches        int,
  surface_m2        int,
  meuble            boolean NOT NULL DEFAULT false,
  etage             int,
  equipements       text[] NOT NULL DEFAULT '{}',
  compteur_electricite text,
  compteur_eau         text,
  statut            statut_bien NOT NULL DEFAULT 'BROUILLON',
  motif_rejet       text,
  verifie_par_id    uuid REFERENCES utilisateur(id),
  verifie_le        timestamptz,
  created_at        timestamptz NOT NULL DEFAULT now(),
  updated_at        timestamptz NOT NULL DEFAULT now(),
  deleted_at        timestamptz
);
CREATE INDEX idx_bien_recherche ON bien (ville_id, quartier_id, statut);
CREATE INDEX idx_bien_geo_floue ON bien USING gist (position_floue);

CREATE TABLE mandat (
  id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  bien_id       uuid NOT NULL REFERENCES bien(id) ON DELETE CASCADE,
  agent_id      uuid REFERENCES agent(id),
  type          type_mandat NOT NULL DEFAULT 'SIMPLE',
  taux_commission numeric(5,2),
  debut         date NOT NULL DEFAULT CURRENT_DATE,
  fin           date,
  actif         boolean NOT NULL DEFAULT true
);

CREATE TABLE annonce (
  id                  uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  bien_id             uuid NOT NULL REFERENCES bien(id) ON DELETE CASCADE,
  titre               text NOT NULL,
  description         text,
  loyer_mensuel       bigint NOT NULL,            -- XAF
  charges_mensuelles  bigint NOT NULL DEFAULT 0,
  charges_incluses    boolean NOT NULL DEFAULT false,
  avance_mois         int NOT NULL DEFAULT 2,     -- Avance spécifique Cameroun
  caution_mois        int NOT NULL DEFAULT 1,
  negociable          boolean NOT NULL DEFAULT false,
  disponible_le       date,
  publiee_le          timestamptz,
  expire_le           timestamptz,
  confirmee_le        timestamptz,
  boost_jusqu_a       timestamptz,
  nb_vues             int NOT NULL DEFAULT 0,
  nb_demandes_visite  int NOT NULL DEFAULT 0,
  recherche_tsv       tsvector,
  created_at          timestamptz NOT NULL DEFAULT now(),
  updated_at          timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX idx_annonce_loyer ON annonce (loyer_mensuel);
CREATE INDEX idx_annonce_tsv ON annonce USING gin (recherche_tsv);

CREATE TABLE media (
  id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  bien_id       uuid NOT NULL REFERENCES bien(id) ON DELETE CASCADE,
  storage_key   text NOT NULL,
  ordre         int NOT NULL DEFAULT 0,
  largeur       int, hauteur int, taille_octets int,
  phash         text,
  piece         text,
  created_at    timestamptz NOT NULL DEFAULT now()
);

-- =========================================================
-- VISITES
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
  code_confirmation text,
  checkin_position  geography(Point,4326),
  checkin_le        timestamptz,
  confirmee_le      timestamptz,
  motif_contestation text,
  rembourse_le      timestamptz,
  created_at        timestamptz NOT NULL DEFAULT now()
);

-- =========================================================
-- PAIEMENTS & COMPTABILITE DOUBLE ENTREE
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
  idempotency_key   text UNIQUE NOT NULL,
  created_at        timestamptz NOT NULL DEFAULT now(),
  regle_le          timestamptz
);

CREATE TABLE ecriture (
  id            bigserial PRIMARY KEY,
  paiement_id   uuid REFERENCES paiement(id),
  compte        text NOT NULL,
  sens          char(1) NOT NULL CHECK (sens IN ('D','C')),
  montant       bigint NOT NULL CHECK (montant > 0),
  libelle       text,
  created_at    timestamptz NOT NULL DEFAULT now()
);
