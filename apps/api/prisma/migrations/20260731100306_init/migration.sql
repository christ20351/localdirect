-- CreateEnum
CREATE TYPE "RoleUtilisateur" AS ENUM ('LOCATAIRE', 'BAILLEUR', 'AGENT', 'STAFF', 'ADMIN');

-- CreateEnum
CREATE TYPE "StatutKyc" AS ENUM ('NON_SOUMIS', 'EN_ATTENTE', 'VALIDE', 'REJETE', 'EXPIRE');

-- CreateEnum
CREATE TYPE "StatutVille" AS ENUM ('FERMEE', 'PRE_LANCEMENT', 'OUVERTE');

-- CreateEnum
CREATE TYPE "TypeBien" AS ENUM ('CHAMBRE_SIMPLE', 'CHAMBRE_MODERNE', 'STUDIO', 'APPARTEMENT', 'DUPLEX', 'MAISON', 'VILLA', 'BOUTIQUE', 'BUREAU', 'TERRAIN');

-- CreateEnum
CREATE TYPE "StatutBien" AS ENUM ('BROUILLON', 'EN_VERIFICATION', 'DISPONIBLE', 'RESERVE', 'LOUE', 'SUSPENDU', 'EXPIRE', 'REJETE');

-- CreateEnum
CREATE TYPE "TypeMandat" AS ENUM ('SIMPLE', 'EXCLUSIF', 'PROPRIETAIRE_DIRECT');

-- CreateEnum
CREATE TYPE "StatutVisite" AS ENUM ('DEMANDEE', 'PAYEE', 'PLANIFIEE', 'CHECK_IN', 'REALISEE', 'CONFIRMEE', 'CONTESTEE', 'ANNULEE', 'REMBOURSEE', 'NO_SHOW');

-- CreateEnum
CREATE TYPE "StatutCandidature" AS ENUM ('BROUILLON', 'SOUMISE', 'EN_EXAMEN', 'ACCEPTEE', 'REFUSEE', 'RETIREE');

-- CreateEnum
CREATE TYPE "StatutBail" AS ENUM ('PROJET', 'A_SIGNER', 'ACTIF', 'PREAVIS', 'TERMINE', 'RESILIE', 'LITIGE');

-- CreateEnum
CREATE TYPE "TypePaiement" AS ENUM ('FRAIS_VISITE', 'FRAIS_SERVICE', 'BOOST', 'AVANCE', 'CAUTION', 'LOYER', 'REVERSEMENT_AGENT', 'REMBOURSEMENT');

-- CreateEnum
CREATE TYPE "StatutPaiement" AS ENUM ('INITIE', 'EN_ATTENTE', 'REUSSI', 'ECHOUE', 'ANNULE', 'REMBOURSE');

-- CreateEnum
CREATE TYPE "MethodePaiement" AS ENUM ('MTN_MOMO', 'ORANGE_MONEY', 'CARTE', 'VIREMENT', 'ESPECES');

-- CreateEnum
CREATE TYPE "TypeEtatLieux" AS ENUM ('ENTREE', 'SORTIE');

-- CreateEnum
CREATE TYPE "StatutLitige" AS ENUM ('OUVERT', 'EN_INSTRUCTION', 'RESOLU', 'REJETE', 'ESCALADE');

-- CreateEnum
CREATE TYPE "Langue" AS ENUM ('FR', 'EN');

-- CreateTable
CREATE TABLE "ville" (
    "id" UUID NOT NULL,
    "nom" TEXT NOT NULL,
    "region" TEXT NOT NULL,
    "slug" TEXT NOT NULL,
    "statut" "StatutVille" NOT NULL DEFAULT 'FERMEE',
    "latitude" DOUBLE PRECISION,
    "longitude" DOUBLE PRECISION,
    "parametres" JSONB NOT NULL DEFAULT '{}',
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "ville_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "quartier" (
    "id" UUID NOT NULL,
    "ville_id" UUID NOT NULL,
    "nom" TEXT NOT NULL,
    "slug" TEXT NOT NULL,
    "aliases" TEXT[] DEFAULT ARRAY[]::TEXT[],
    "latitude" DOUBLE PRECISION,
    "longitude" DOUBLE PRECISION,
    "actif" BOOLEAN NOT NULL DEFAULT true,

    CONSTRAINT "quartier_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "point_repere" (
    "id" UUID NOT NULL,
    "quartier_id" UUID NOT NULL,
    "nom" TEXT NOT NULL,
    "latitude" DOUBLE PRECISION NOT NULL,
    "longitude" DOUBLE PRECISION NOT NULL,

    CONSTRAINT "point_repere_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "utilisateur" (
    "id" UUID NOT NULL,
    "telephone" TEXT NOT NULL,
    "telephone_verifie" BOOLEAN NOT NULL DEFAULT false,
    "email" TEXT,
    "nom_complet" TEXT,
    "photo_url" TEXT,
    "roles" "RoleUtilisateur"[] DEFAULT ARRAY['LOCATAIRE']::"RoleUtilisateur"[],
    "langue" "Langue" NOT NULL DEFAULT 'FR',
    "ville_id" UUID,
    "statut_kyc" "StatutKyc" NOT NULL DEFAULT 'NON_SOUMIS',
    "mot_de_passe_hash" TEXT,
    "whatsapp_optin" BOOLEAN NOT NULL DEFAULT false,
    "derniere_activite" TIMESTAMP(3),
    "bloque" BOOLEAN NOT NULL DEFAULT false,
    "motif_blocage" TEXT,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,
    "deleted_at" TIMESTAMP(3),

    CONSTRAINT "utilisateur_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "document_verification" (
    "id" UUID NOT NULL,
    "utilisateur_id" UUID NOT NULL,
    "type" TEXT NOT NULL,
    "storage_key" TEXT NOT NULL,
    "hash_sha256" TEXT NOT NULL,
    "statut" "StatutKyc" NOT NULL DEFAULT 'EN_ATTENTE',
    "motif_rejet" TEXT,
    "verifie_par" UUID,
    "verifie_le" TIMESTAMP(3),
    "purge_le" DATE,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "document_verification_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "agent" (
    "id" UUID NOT NULL,
    "utilisateur_id" UUID NOT NULL,
    "code_agent" TEXT NOT NULL,
    "ville_id" UUID NOT NULL,
    "quartiers_couverts" TEXT[] DEFAULT ARRAY[]::TEXT[],
    "numero_momo" TEXT NOT NULL,
    "caution_deposee" BIGINT NOT NULL DEFAULT 0,
    "score" DOUBLE PRECISION NOT NULL DEFAULT 50.0,
    "nb_visites" INTEGER NOT NULL DEFAULT 0,
    "nb_visites_ok" INTEGER NOT NULL DEFAULT 0,
    "nb_baux" INTEGER NOT NULL DEFAULT 0,
    "suspendu" BOOLEAN NOT NULL DEFAULT false,
    "charte_signee_le" TIMESTAMP(3),
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "agent_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "bien" (
    "id" UUID NOT NULL,
    "reference" TEXT NOT NULL,
    "bailleur_id" UUID,
    "bailleur_tel" TEXT,
    "cree_par_id" UUID NOT NULL,
    "ville_id" UUID NOT NULL,
    "quartier_id" UUID NOT NULL,
    "point_repere_id" UUID,
    "indication_acces" TEXT,
    "latitude" DOUBLE PRECISION,
    "longitude" DOUBLE PRECISION,
    "latitude_floue" DOUBLE PRECISION,
    "longitude_floue" DOUBLE PRECISION,
    "type" "TypeBien" NOT NULL,
    "nb_pieces" INTEGER,
    "nb_chambres" INTEGER,
    "nb_douches" INTEGER,
    "surface_m2" INTEGER,
    "meuble" BOOLEAN NOT NULL DEFAULT false,
    "etage" INTEGER,
    "equipements" TEXT[] DEFAULT ARRAY[]::TEXT[],
    "compteur_electricite" TEXT,
    "compteur_eau" TEXT,
    "statut" "StatutBien" NOT NULL DEFAULT 'BROUILLON',
    "motif_rejet" TEXT,
    "verifie_par_id" UUID,
    "verifie_le" TIMESTAMP(3),
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,
    "deleted_at" TIMESTAMP(3),

    CONSTRAINT "bien_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "mandat" (
    "id" UUID NOT NULL,
    "bien_id" UUID NOT NULL,
    "agent_id" UUID,
    "type" "TypeMandat" NOT NULL DEFAULT 'SIMPLE',
    "taux_commission" DOUBLE PRECISION,
    "debut" DATE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "fin" DATE,
    "actif" BOOLEAN NOT NULL DEFAULT true,

    CONSTRAINT "mandat_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "annonce" (
    "id" UUID NOT NULL,
    "bien_id" UUID NOT NULL,
    "titre" TEXT NOT NULL,
    "description" TEXT,
    "loyer_mensuel" BIGINT NOT NULL,
    "charges_mensuelles" BIGINT NOT NULL DEFAULT 0,
    "charges_incluses" BOOLEAN NOT NULL DEFAULT false,
    "avance_mois" INTEGER NOT NULL DEFAULT 2,
    "caution_mois" INTEGER NOT NULL DEFAULT 1,
    "negociable" BOOLEAN NOT NULL DEFAULT false,
    "disponible_le" DATE,
    "publiee_le" TIMESTAMP(3),
    "expire_le" TIMESTAMP(3),
    "confirmee_le" TIMESTAMP(3),
    "boost_jusqu_a" TIMESTAMP(3),
    "nb_vues" INTEGER NOT NULL DEFAULT 0,
    "nb_demandes_visite" INTEGER NOT NULL DEFAULT 0,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "annonce_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "media" (
    "id" UUID NOT NULL,
    "bien_id" UUID NOT NULL,
    "storage_key" TEXT NOT NULL,
    "ordre" INTEGER NOT NULL DEFAULT 0,
    "largeur" INTEGER,
    "hauteur" INTEGER,
    "taille_octets" INTEGER,
    "phash" TEXT,
    "piece" TEXT,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "media_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "favori" (
    "utilisateur_id" UUID NOT NULL,
    "annonce_id" UUID NOT NULL,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "favori_pkey" PRIMARY KEY ("utilisateur_id","annonce_id")
);

-- CreateTable
CREATE TABLE "alerte_recherche" (
    "id" UUID NOT NULL,
    "utilisateur_id" UUID NOT NULL,
    "criteres" JSONB NOT NULL,
    "canal" TEXT NOT NULL DEFAULT 'PUSH',
    "actif" BOOLEAN NOT NULL DEFAULT true,
    "derniere_notif" TIMESTAMP(3),

    CONSTRAINT "alerte_recherche_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "visite" (
    "id" UUID NOT NULL,
    "annonce_id" UUID NOT NULL,
    "locataire_id" UUID NOT NULL,
    "agent_id" UUID,
    "statut" "StatutVisite" NOT NULL DEFAULT 'DEMANDEE',
    "creneau_debut" TIMESTAMP(3),
    "creneau_fin" TIMESTAMP(3),
    "frais" BIGINT NOT NULL,
    "paiement_id" UUID,
    "code_confirmation" TEXT,
    "checkin_latitude" DOUBLE PRECISION,
    "checkin_longitude" DOUBLE PRECISION,
    "checkin_le" TIMESTAMP(3),
    "confirmee_le" TIMESTAMP(3),
    "motif_contestation" TEXT,
    "rembourse_le" TIMESTAMP(3),
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "visite_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "garant" (
    "id" UUID NOT NULL,
    "locataire_id" UUID NOT NULL,
    "nom_complet" TEXT NOT NULL,
    "telephone" TEXT NOT NULL,
    "profession" TEXT,
    "lien" TEXT,
    "cni_document_id" UUID,
    "verifie" BOOLEAN NOT NULL DEFAULT false,

    CONSTRAINT "garant_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "candidature" (
    "id" UUID NOT NULL,
    "annonce_id" UUID NOT NULL,
    "locataire_id" UUID NOT NULL,
    "visite_id" UUID,
    "statut" "StatutCandidature" NOT NULL DEFAULT 'BROUILLON',
    "revenu_declare" BIGINT,
    "source_revenu" TEXT,
    "garant_id" UUID,
    "nb_occupants" INTEGER,
    "message" TEXT,
    "motif_refus" TEXT,
    "soumise_le" TIMESTAMP(3),
    "decidee_le" TIMESTAMP(3),

    CONSTRAINT "candidature_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "bail" (
    "id" UUID NOT NULL,
    "reference" TEXT NOT NULL,
    "bien_id" UUID NOT NULL,
    "bailleur_id" UUID NOT NULL,
    "locataire_id" UUID NOT NULL,
    "agent_id" UUID,
    "candidature_id" UUID,
    "statut" "StatutBail" NOT NULL DEFAULT 'PROJET',
    "date_debut" DATE NOT NULL,
    "date_fin" DATE,
    "duree_mois" INTEGER,
    "loyer_mensuel" BIGINT NOT NULL,
    "charges_mensuelles" BIGINT NOT NULL DEFAULT 0,
    "jour_echeance" INTEGER NOT NULL DEFAULT 5,
    "avance_mois" INTEGER NOT NULL DEFAULT 2,
    "avance_montant" BIGINT NOT NULL DEFAULT 0,
    "caution_montant" BIGINT NOT NULL DEFAULT 0,
    "caution_detenue_par" TEXT NOT NULL DEFAULT 'BAILLEUR',
    "precompte_applicable" BOOLEAN NOT NULL DEFAULT true,
    "taux_precompte" DOUBLE PRECISION NOT NULL DEFAULT 10.00,
    "pdf_storage_key" TEXT,
    "pdf_signe_key" TEXT,
    "signe_le" TIMESTAMP(3),
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "bail_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "echeance_loyer" (
    "id" UUID NOT NULL,
    "bail_id" UUID NOT NULL,
    "periode" DATE NOT NULL,
    "montant_du" BIGINT NOT NULL,
    "montant_paye" BIGINT NOT NULL DEFAULT 0,
    "date_limite" DATE NOT NULL,
    "quittance_key" TEXT,

    CONSTRAINT "echeance_loyer_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "paiement" (
    "id" UUID NOT NULL,
    "reference" TEXT NOT NULL,
    "payeur_id" UUID,
    "beneficiaire_id" UUID,
    "type" "TypePaiement" NOT NULL,
    "statut" "StatutPaiement" NOT NULL DEFAULT 'INITIE',
    "methode" "MethodePaiement",
    "montant" BIGINT NOT NULL,
    "frais_psp" BIGINT NOT NULL DEFAULT 0,
    "devise" CHAR(3) NOT NULL DEFAULT 'XAF',
    "visite_id" UUID,
    "bail_id" UUID,
    "echeance_id" UUID,
    "annonce_id" UUID,
    "idempotency_key" TEXT NOT NULL,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "regle_le" TIMESTAMP(3),

    CONSTRAINT "paiement_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "transaction_psp" (
    "id" UUID NOT NULL,
    "paiement_id" UUID NOT NULL,
    "psp" TEXT NOT NULL,
    "psp_reference" TEXT,
    "operateur" TEXT,
    "numero" TEXT,
    "requete" JSONB,
    "reponse" JSONB,
    "webhook_recu_le" TIMESTAMP(3),
    "statut_brut" TEXT,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "transaction_psp_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "ecriture" (
    "id" BIGSERIAL NOT NULL,
    "paiement_id" UUID,
    "compte" TEXT NOT NULL,
    "sens" CHAR(1) NOT NULL,
    "montant" BIGINT NOT NULL,
    "libelle" TEXT,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "ecriture_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "retrait_agent" (
    "id" UUID NOT NULL,
    "agent_id" UUID NOT NULL,
    "montant" BIGINT NOT NULL,
    "numero_momo" TEXT NOT NULL,
    "statut" "StatutPaiement" NOT NULL DEFAULT 'INITIE',
    "paiement_id" UUID,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "retrait_agent_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "etat_lieux" (
    "id" UUID NOT NULL,
    "bail_id" UUID NOT NULL,
    "type" "TypeEtatLieux" NOT NULL,
    "realise_le" TIMESTAMP(3),
    "signe_bailleur" BOOLEAN NOT NULL DEFAULT false,
    "signe_locataire" BOOLEAN NOT NULL DEFAULT false,
    "pdf_key" TEXT,

    CONSTRAINT "etat_lieux_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "etat_lieux_item" (
    "id" UUID NOT NULL,
    "etat_lieux_id" UUID NOT NULL,
    "piece" TEXT NOT NULL,
    "element" TEXT NOT NULL,
    "etat" TEXT NOT NULL,
    "commentaire" TEXT,
    "media_keys" TEXT[] DEFAULT ARRAY[]::TEXT[],

    CONSTRAINT "etat_lieux_item_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "avis" (
    "id" UUID NOT NULL,
    "auteur_id" UUID NOT NULL,
    "cible_id" UUID NOT NULL,
    "bail_id" UUID,
    "visite_id" UUID,
    "note" INTEGER NOT NULL,
    "commentaire" TEXT,
    "publie" BOOLEAN NOT NULL DEFAULT false,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "avis_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "signalement" (
    "id" UUID NOT NULL,
    "auteur_id" UUID,
    "cible_type" TEXT NOT NULL,
    "cible_id" UUID NOT NULL,
    "motif" TEXT NOT NULL,
    "details" TEXT,
    "traite_le" TIMESTAMP(3),
    "traite_par" UUID,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "signalement_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "litige" (
    "id" UUID NOT NULL,
    "bail_id" UUID,
    "visite_id" UUID,
    "ouvert_par_id" UUID NOT NULL,
    "categorie" TEXT NOT NULL,
    "statut" "StatutLitige" NOT NULL DEFAULT 'OUVERT',
    "montant_conteste" BIGINT,
    "decision" TEXT,
    "assigne_a" UUID,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "clos_le" TIMESTAMP(3),

    CONSTRAINT "litige_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "conversation" (
    "id" UUID NOT NULL,
    "annonce_id" UUID,
    "bail_id" UUID,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "conversation_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "participant_conversation" (
    "conversation_id" UUID NOT NULL,
    "utilisateur_id" UUID NOT NULL,
    "lu_jusqu_a" TIMESTAMP(3),

    CONSTRAINT "participant_conversation_pkey" PRIMARY KEY ("conversation_id","utilisateur_id")
);

-- CreateTable
CREATE TABLE "message" (
    "id" UUID NOT NULL,
    "conversation_id" UUID NOT NULL,
    "expediteur_id" UUID NOT NULL,
    "contenu" TEXT NOT NULL,
    "media_key" TEXT,
    "masque" BOOLEAN NOT NULL DEFAULT false,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "message_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "notification" (
    "id" UUID NOT NULL,
    "utilisateur_id" UUID NOT NULL,
    "canal" TEXT NOT NULL,
    "gabarit" TEXT NOT NULL,
    "variables" JSONB NOT NULL DEFAULT '{}',
    "envoye_le" TIMESTAMP(3),
    "lu_le" TIMESTAMP(3),
    "erreur" TEXT,

    CONSTRAINT "notification_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "otp" (
    "id" UUID NOT NULL,
    "telephone" TEXT NOT NULL,
    "code_hash" TEXT NOT NULL,
    "canal" TEXT NOT NULL DEFAULT 'SMS',
    "tentatives" INTEGER NOT NULL DEFAULT 0,
    "expire_le" TIMESTAMP(3) NOT NULL,
    "consomme_le" TIMESTAMP(3),
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "otp_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "journal_audit" (
    "id" BIGSERIAL NOT NULL,
    "acteur_id" UUID,
    "action" TEXT NOT NULL,
    "entite" TEXT NOT NULL,
    "entite_id" UUID,
    "avant" JSONB,
    "apres" JSONB,
    "ip" TEXT,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "journal_audit_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "reference_prix" (
    "id" UUID NOT NULL,
    "quartier_id" UUID NOT NULL,
    "type" "TypeBien" NOT NULL,
    "nb_pieces" INTEGER,
    "loyer_p25" BIGINT,
    "loyer_median" BIGINT,
    "loyer_p75" BIGINT,
    "echantillon" INTEGER NOT NULL DEFAULT 0,
    "calcule_le" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "reference_prix_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "ville_slug_key" ON "ville"("slug");

-- CreateIndex
CREATE UNIQUE INDEX "quartier_ville_id_slug_key" ON "quartier"("ville_id", "slug");

-- CreateIndex
CREATE UNIQUE INDEX "utilisateur_telephone_key" ON "utilisateur"("telephone");

-- CreateIndex
CREATE UNIQUE INDEX "utilisateur_email_key" ON "utilisateur"("email");

-- CreateIndex
CREATE UNIQUE INDEX "agent_utilisateur_id_key" ON "agent"("utilisateur_id");

-- CreateIndex
CREATE UNIQUE INDEX "agent_code_agent_key" ON "agent"("code_agent");

-- CreateIndex
CREATE UNIQUE INDEX "bien_reference_key" ON "bien"("reference");

-- CreateIndex
CREATE INDEX "bien_ville_id_quartier_id_statut_idx" ON "bien"("ville_id", "quartier_id", "statut");

-- CreateIndex
CREATE INDEX "annonce_loyer_mensuel_idx" ON "annonce"("loyer_mensuel");

-- CreateIndex
CREATE INDEX "media_phash_idx" ON "media"("phash");

-- CreateIndex
CREATE INDEX "visite_agent_id_statut_idx" ON "visite"("agent_id", "statut");

-- CreateIndex
CREATE INDEX "visite_locataire_id_created_at_idx" ON "visite"("locataire_id", "created_at");

-- CreateIndex
CREATE UNIQUE INDEX "candidature_annonce_id_locataire_id_key" ON "candidature"("annonce_id", "locataire_id");

-- CreateIndex
CREATE UNIQUE INDEX "bail_reference_key" ON "bail"("reference");

-- CreateIndex
CREATE UNIQUE INDEX "echeance_loyer_bail_id_periode_key" ON "echeance_loyer"("bail_id", "periode");

-- CreateIndex
CREATE UNIQUE INDEX "paiement_reference_key" ON "paiement"("reference");

-- CreateIndex
CREATE UNIQUE INDEX "paiement_idempotency_key_key" ON "paiement"("idempotency_key");

-- CreateIndex
CREATE UNIQUE INDEX "transaction_psp_psp_psp_reference_key" ON "transaction_psp"("psp", "psp_reference");

-- CreateIndex
CREATE INDEX "ecriture_compte_created_at_idx" ON "ecriture"("compte", "created_at");

-- CreateIndex
CREATE INDEX "otp_telephone_created_at_idx" ON "otp"("telephone", "created_at" DESC);

-- CreateIndex
CREATE UNIQUE INDEX "reference_prix_quartier_id_type_nb_pieces_key" ON "reference_prix"("quartier_id", "type", "nb_pieces");

-- AddForeignKey
ALTER TABLE "quartier" ADD CONSTRAINT "quartier_ville_id_fkey" FOREIGN KEY ("ville_id") REFERENCES "ville"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "point_repere" ADD CONSTRAINT "point_repere_quartier_id_fkey" FOREIGN KEY ("quartier_id") REFERENCES "quartier"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "utilisateur" ADD CONSTRAINT "utilisateur_ville_id_fkey" FOREIGN KEY ("ville_id") REFERENCES "ville"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "document_verification" ADD CONSTRAINT "document_verification_utilisateur_id_fkey" FOREIGN KEY ("utilisateur_id") REFERENCES "utilisateur"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "document_verification" ADD CONSTRAINT "document_verification_verifie_par_fkey" FOREIGN KEY ("verifie_par") REFERENCES "utilisateur"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "agent" ADD CONSTRAINT "agent_utilisateur_id_fkey" FOREIGN KEY ("utilisateur_id") REFERENCES "utilisateur"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "agent" ADD CONSTRAINT "agent_ville_id_fkey" FOREIGN KEY ("ville_id") REFERENCES "ville"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "bien" ADD CONSTRAINT "bien_bailleur_id_fkey" FOREIGN KEY ("bailleur_id") REFERENCES "utilisateur"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "bien" ADD CONSTRAINT "bien_cree_par_id_fkey" FOREIGN KEY ("cree_par_id") REFERENCES "utilisateur"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "bien" ADD CONSTRAINT "bien_ville_id_fkey" FOREIGN KEY ("ville_id") REFERENCES "ville"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "bien" ADD CONSTRAINT "bien_quartier_id_fkey" FOREIGN KEY ("quartier_id") REFERENCES "quartier"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "bien" ADD CONSTRAINT "bien_point_repere_id_fkey" FOREIGN KEY ("point_repere_id") REFERENCES "point_repere"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "bien" ADD CONSTRAINT "bien_verifie_par_id_fkey" FOREIGN KEY ("verifie_par_id") REFERENCES "utilisateur"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "mandat" ADD CONSTRAINT "mandat_bien_id_fkey" FOREIGN KEY ("bien_id") REFERENCES "bien"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "mandat" ADD CONSTRAINT "mandat_agent_id_fkey" FOREIGN KEY ("agent_id") REFERENCES "agent"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "annonce" ADD CONSTRAINT "annonce_bien_id_fkey" FOREIGN KEY ("bien_id") REFERENCES "bien"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "media" ADD CONSTRAINT "media_bien_id_fkey" FOREIGN KEY ("bien_id") REFERENCES "bien"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "favori" ADD CONSTRAINT "favori_utilisateur_id_fkey" FOREIGN KEY ("utilisateur_id") REFERENCES "utilisateur"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "favori" ADD CONSTRAINT "favori_annonce_id_fkey" FOREIGN KEY ("annonce_id") REFERENCES "annonce"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "alerte_recherche" ADD CONSTRAINT "alerte_recherche_utilisateur_id_fkey" FOREIGN KEY ("utilisateur_id") REFERENCES "utilisateur"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "visite" ADD CONSTRAINT "visite_annonce_id_fkey" FOREIGN KEY ("annonce_id") REFERENCES "annonce"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "visite" ADD CONSTRAINT "visite_locataire_id_fkey" FOREIGN KEY ("locataire_id") REFERENCES "utilisateur"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "visite" ADD CONSTRAINT "visite_agent_id_fkey" FOREIGN KEY ("agent_id") REFERENCES "agent"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "garant" ADD CONSTRAINT "garant_locataire_id_fkey" FOREIGN KEY ("locataire_id") REFERENCES "utilisateur"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "garant" ADD CONSTRAINT "garant_cni_document_id_fkey" FOREIGN KEY ("cni_document_id") REFERENCES "document_verification"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "candidature" ADD CONSTRAINT "candidature_annonce_id_fkey" FOREIGN KEY ("annonce_id") REFERENCES "annonce"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "candidature" ADD CONSTRAINT "candidature_locataire_id_fkey" FOREIGN KEY ("locataire_id") REFERENCES "utilisateur"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "candidature" ADD CONSTRAINT "candidature_visite_id_fkey" FOREIGN KEY ("visite_id") REFERENCES "visite"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "candidature" ADD CONSTRAINT "candidature_garant_id_fkey" FOREIGN KEY ("garant_id") REFERENCES "garant"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "bail" ADD CONSTRAINT "bail_bien_id_fkey" FOREIGN KEY ("bien_id") REFERENCES "bien"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "bail" ADD CONSTRAINT "bail_bailleur_id_fkey" FOREIGN KEY ("bailleur_id") REFERENCES "utilisateur"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "bail" ADD CONSTRAINT "bail_locataire_id_fkey" FOREIGN KEY ("locataire_id") REFERENCES "utilisateur"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "bail" ADD CONSTRAINT "bail_agent_id_fkey" FOREIGN KEY ("agent_id") REFERENCES "agent"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "bail" ADD CONSTRAINT "bail_candidature_id_fkey" FOREIGN KEY ("candidature_id") REFERENCES "candidature"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "echeance_loyer" ADD CONSTRAINT "echeance_loyer_bail_id_fkey" FOREIGN KEY ("bail_id") REFERENCES "bail"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "paiement" ADD CONSTRAINT "paiement_payeur_id_fkey" FOREIGN KEY ("payeur_id") REFERENCES "utilisateur"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "paiement" ADD CONSTRAINT "paiement_beneficiaire_id_fkey" FOREIGN KEY ("beneficiaire_id") REFERENCES "utilisateur"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "paiement" ADD CONSTRAINT "paiement_visite_id_fkey" FOREIGN KEY ("visite_id") REFERENCES "visite"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "paiement" ADD CONSTRAINT "paiement_bail_id_fkey" FOREIGN KEY ("bail_id") REFERENCES "bail"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "paiement" ADD CONSTRAINT "paiement_echeance_id_fkey" FOREIGN KEY ("echeance_id") REFERENCES "echeance_loyer"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "paiement" ADD CONSTRAINT "paiement_annonce_id_fkey" FOREIGN KEY ("annonce_id") REFERENCES "annonce"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "transaction_psp" ADD CONSTRAINT "transaction_psp_paiement_id_fkey" FOREIGN KEY ("paiement_id") REFERENCES "paiement"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "ecriture" ADD CONSTRAINT "ecriture_paiement_id_fkey" FOREIGN KEY ("paiement_id") REFERENCES "paiement"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "retrait_agent" ADD CONSTRAINT "retrait_agent_agent_id_fkey" FOREIGN KEY ("agent_id") REFERENCES "agent"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "retrait_agent" ADD CONSTRAINT "retrait_agent_paiement_id_fkey" FOREIGN KEY ("paiement_id") REFERENCES "paiement"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "etat_lieux" ADD CONSTRAINT "etat_lieux_bail_id_fkey" FOREIGN KEY ("bail_id") REFERENCES "bail"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "etat_lieux_item" ADD CONSTRAINT "etat_lieux_item_etat_lieux_id_fkey" FOREIGN KEY ("etat_lieux_id") REFERENCES "etat_lieux"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "avis" ADD CONSTRAINT "avis_auteur_id_fkey" FOREIGN KEY ("auteur_id") REFERENCES "utilisateur"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "avis" ADD CONSTRAINT "avis_cible_id_fkey" FOREIGN KEY ("cible_id") REFERENCES "utilisateur"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "avis" ADD CONSTRAINT "avis_bail_id_fkey" FOREIGN KEY ("bail_id") REFERENCES "bail"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "avis" ADD CONSTRAINT "avis_visite_id_fkey" FOREIGN KEY ("visite_id") REFERENCES "visite"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "signalement" ADD CONSTRAINT "signalement_auteur_id_fkey" FOREIGN KEY ("auteur_id") REFERENCES "utilisateur"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "signalement" ADD CONSTRAINT "signalement_traite_par_fkey" FOREIGN KEY ("traite_par") REFERENCES "utilisateur"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "litige" ADD CONSTRAINT "litige_bail_id_fkey" FOREIGN KEY ("bail_id") REFERENCES "bail"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "litige" ADD CONSTRAINT "litige_visite_id_fkey" FOREIGN KEY ("visite_id") REFERENCES "visite"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "litige" ADD CONSTRAINT "litige_ouvert_par_id_fkey" FOREIGN KEY ("ouvert_par_id") REFERENCES "utilisateur"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "litige" ADD CONSTRAINT "litige_assigne_a_fkey" FOREIGN KEY ("assigne_a") REFERENCES "utilisateur"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "conversation" ADD CONSTRAINT "conversation_annonce_id_fkey" FOREIGN KEY ("annonce_id") REFERENCES "annonce"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "conversation" ADD CONSTRAINT "conversation_bail_id_fkey" FOREIGN KEY ("bail_id") REFERENCES "bail"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "participant_conversation" ADD CONSTRAINT "participant_conversation_conversation_id_fkey" FOREIGN KEY ("conversation_id") REFERENCES "conversation"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "participant_conversation" ADD CONSTRAINT "participant_conversation_utilisateur_id_fkey" FOREIGN KEY ("utilisateur_id") REFERENCES "utilisateur"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "message" ADD CONSTRAINT "message_conversation_id_fkey" FOREIGN KEY ("conversation_id") REFERENCES "conversation"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "message" ADD CONSTRAINT "message_expediteur_id_fkey" FOREIGN KEY ("expediteur_id") REFERENCES "utilisateur"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "notification" ADD CONSTRAINT "notification_utilisateur_id_fkey" FOREIGN KEY ("utilisateur_id") REFERENCES "utilisateur"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "journal_audit" ADD CONSTRAINT "journal_audit_acteur_id_fkey" FOREIGN KEY ("acteur_id") REFERENCES "utilisateur"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "reference_prix" ADD CONSTRAINT "reference_prix_quartier_id_fkey" FOREIGN KEY ("quartier_id") REFERENCES "quartier"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
