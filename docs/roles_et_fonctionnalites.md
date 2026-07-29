# LocaDirect CM — Spécification Complète des Rôles et Fonctionnalités

Document de référence détaillant pour chaque rôle de la plateforme **LocaDirect CM** : ses responsabilités, sa valeur ajoutée, ses étapes d'intervention dans le parcours immobilier camerounais, ainsi que l'ensemble des fonctionnalités à implémenter.

---

## Sommaire des Rôles

1. [Locataire (TENANT)](#1-locataire-tenant)
2. [Agent / Démarcheur Certifié (AGENT)](#2-agent--démarcheur-certifié-agent)
3. [Bailleur / Propriétaire (LANDLORD)](#3-bailleur--propriétaire-landlord)
4. [Staff / Modérateur Opérationnel (STAFF)](#4-staff--modérateur-opérationnel-staff)
5. [Administrateur Système (ADMIN)](#5-administrateur-système-admin)
6. [Matrice Croisée des Parcours et Interactions](#6-matrice-croisée-des-parcours-et-interactions)

---

## 1. Locataire (TENANT)

### 1.1 Profil & Objectif Principal
Le locataire est l'utilisateur final à la recherche d'un logement (chambre moderne, studio, appartement 2-3 pièces, duplex) à Douala, Yaoundé ou d'autres villes du Cameroun. Son objectif est de trouver rapidement un bien disponible, conforme aux photos, et d'effectuer des visites sans se faire escroquer par des démarcheurs véreux.

### 1.2 Valeur Ajoutée & Utilité
* **Visite Garantie Remboursée** : Ne paye les frais de visite (1 500 – 3 000 FCFA par Mobile Money) que pour des biens réels, vérifiés et disponibles. Remboursement automatique en cas d'annonce caduque ou de non-conformité.
* **Transparence Financière Totale** : Voit dès la recherche le détail exact des frais à l'entrée : Loyer mensuel + **Avance (2 à 6 mois)** + **Caution (1 à 2 mois)**.
* **Mode Économie de Données (3G/4G)** : Recherche fluide même avec une connexion faible ou coûteuse en data (liste en texte enrichi d'abord, images en lazy-loading).
* **Dossier Locataire Portable** : Dépose ses pièces (CNI, garant, activité) une seule fois pour candidater à plusieurs logements.

### 1.3 Étapes d'Intervention dans le Parcours
```
1. Recherche/Filtres ➔ 2. Consultation Fiche ➔ 3. Demande & Paiement MoMo ➔ 4. Visite Terrain & Code 4 chiffres ➔ 5. Confirmation/Contestation ➔ 6. Dépôt Candidature ➔ 7. Signature Bail PDF
```

### 1.4 Liste Exhaustive des Fonctionnalités à Implémenter

#### A. Recherche & Exploration
* **Recherche Multi-Critères** : Par Ville, Quartier(s) et Point de repère (ex: *Bonamoussadi - Carrefour Kotto*), Type de bien, Budget max XAF, Nombre de pièces/chambres/douches, Option Meublé/Non meublé, et Avance maximale acceptée.
* **Mode Économie de Data (Toggle 3G)** : Interrupteur permettant de masquer les photos par défaut et de réduire la consommation data à < 100 Ko par session.
* **Alertes de Recherche Personnalisées** : Enregistrement de critères de recherche avec notifications Push, SMS ou WhatsApp dès qu'un bien correspondant est publié.
* **Favoris & Historique Offline** : Mise en mémoire tampon locale (SQLite/Drift) des biens consultés pour accès sans connexion Internet.

#### B. Tunnel de Visite Garantie
* **Demande de Créneau de Visite** : Sélection d'une plage horaire souhaitée avec l'agent assigné.
* **Paiement sécurisé Mobile Money (MTN / Orange)** : Modal de paiement des frais de visite (XAF) via l'agrégateur local (CamPay / Fapshi).
* **Réception des Coordonnées & Itinéraire** : Déblocage automatique de l'itinéraire exact et du contact de l'agent certifié uniquement après confirmation du paiement MoMo.
* **Système de Validation à Code à 4 Chiffres** : Transmission du code secret à l'agent une fois sur le terrain pour valider la visite.
* **Contestation & Demande de Remboursement** : En cas de bien déjà loué, indisponible ou non-conforme, formulaire de litige avec remboursement automatique sous 24h.

#### C. Candidature, Dossier & Bail
* **Gestion du Dossier Locataire** : Import de la CNI (Recto/Verso), justificatif de revenus/activité (bulletin, registre de commerce, attestation) et informations du Garant.
* **Soumission de Candidature** : Envoi du dossier au bailleur en 1 clic après une visite validée.
* **Consultation du Projet de Bail PDF** : Visualisation du contrat de bail généré automatique (conforme au droit civil ou common law camerounais).
* **Upload du Bail Signé & Historique de Quittances** : Téléchargement du contrat signé et accès aux reçus/quittances de loyers.

---

## 2. Agent / Démarcheur Certifié (AGENT)

### 2.1 Profil & Objectif Principal
L'agent (ex-démarcheur réhabilité) est le partenaire terrain clé de LocaDirect CM. Il prospecte les bailleurs, rentre les biens en mandat (simple ou exclusif), prend les photos certifiées, et réalise les visites physiques avec les locataires.

### 2.2 Valeur Ajoutée & Utilité
* **Professionnalisation & Statut Legal** : Obtient un badge « Agent Certifié » avec un QR code vérifiable par les clients.
* **Application Dédiée Terrain** : Assistant guidé d'ajout de bien en < 5 minutes (photos guidées, coordonnées GPS, saisie des repères).
* **Rémunération Directe & Garantie** : Reçoit sa part de commission (ex: 1 400 FCFA sur les 2 000 FCFA de visite) directement sur son compte Mobile Money dès que le locataire valide le code à 4 chiffres.
* **Score de Réputation** : Plus ses annonces sont fraîches et conformes, plus son score augmente et plus il reçoit de demandes de visites.

### 2.3 Étapes d'Intervention dans le Parcours
```
1. Sourcing & Mandat ➔ 2. Ajout Bien sur App ➔ 3. Validation Staff ➔ 4. Réception Demande Visite ➔ 5. Check-in GPS sur Place ➔ 6. Saisie Code 4 chiffres ➔ 7. Encaissement Commission MoMo
```

### 2.4 Liste Exhaustive des Fonctionnalités à Implémenter

#### A. Onboarding & Profil Agent
* **Procédure KYC Agent** : Upload CNI + Selfie + Numéro MoMo au même nom + Signature de la Charte de Bonne Conduite.
* **Dépôt de Caution de Garantie (Optionnel)** : Possibilité de déposer une caution (10 000 FCFA) pour débloquer le badge « Agent Garanti » et prioriser ses annonces.
* **Gestion de Zone Couverte** : Sélection des quartiers de spécialité par ville (ex: Douala - Makèpè, Logpom).

#### B. Publication & Gestion de l'Inventaire
* **Wizard d'Ajout de Bien Terrain** :
  * Étape 1 : Type de bien, loyer, charges, avance (mois), caution (mois), compteurs ENEO/CAMWATER.
  * Étape 2 : Photos guidées par pièce (Salon, Chambre, Douche, Cuisine, Extérieur) avec horodatage et géolocalisation.
  * Étape 3 : Saisie des points de repère et de l'accès ("Après la pharmacie, portail vert").
  * Étape 4 : Upload de la Preuve de Propriété / Mandat (Facture ENEO, CNI bailleur, attestation chefferie ou acte de vente).
* **Gestion des Mandats** : Suivi des mandats actifs (Simples ou Exclusifs) et des taux de commission négociés.
* **Reconfirmation de Fraîcheur** : Notification hebdomadaire pour relancer la disponibilité du bien d'un simple clic (évite la péremption à 30 jours).

#### C. Réalisation de Visite & Check-in GPS
* **Agenda des Visites** : Vue calendrier des visites planifiées avec rappels d'horaires.
* **Check-in GPS Terrain** : Bouton d'arrivée sur les lieux vérifiant la position géographique de l'agent par rapport au bien.
* **Valideur de Code Visite** : Champ de saisie du code à 4 chiffres fourni par le locataire pour déclencher la clôture de visite.

#### D. Portefeuille & Retraits Mobile Money
* **Tableau de Bord des Gains** : Solde en temps réel (commissions visites + commissions signatures baux).
* **Demande de Retrait MoMo** : Transfert direct vers son compte MTN / Orange Money dès le seuil minimum atteint (5 000 FCFA).

---

## 3. Bailleur / Propriétaire (LANDLORD)

### 3.1 Profil & Objectif Principal
Le bailleur est le propriétaire physique ou moral du logement. Il cherche à réduire la vacance locative, trouver des locataires solvables et sérieux, et simplifier la gestion administrative de ses baux.

### 3.2 Valeur Ajoutée & Utilité
* **Publication Gratuite** : Ne paie aucun abonnement ni frais pour publier ses biens.
* **Vérification des Locataires** : Reçoit des dossiers complets (CNI, garant vérifié, niveau de revenu) avant de faire visiter ou signer.
* **Gestion Fiscale & Juridique Intégrée** : Calcule automatiquement la retenue à la source du **Précompte sur Loyer (10%)** et fournit des récapitulatifs annuels conformes au fisc camerounais.
* **Quittances & Relances Automatiques** : Émissions automatisées des quittances de loyer.

### 3.3 Étapes d'Intervention dans le Parcours
```
1. Inscription / Revendication du Bien ➔ 2. Validation Mandat ➔ 3. Examen des Candidatures ➔ 4. Acceptation/Refus ➔ 5. Réception & Signature du Bail PDF ➔ 6. Suivi des Loyer & Précompte Fisc
```

### 3.4 Liste Exhaustive des Fonctionnalités à Implémenter

#### A. Gestion du Patrimoine
* **Création Directe ou Validation par Mandat** : Possibilité de publier ses biens en autonomie ou de valider l'enregistrement fait par un agent partenaire.
* **Tableau de Bord des Biens** : Vue synthétique de l'état de ses biens (Disponible, Réservé, Loué, En rénovation).

#### B. Examen des Candidatures
* **Revue de Dossier Locataire** : Consultation sécurisée de la CNI du candidat, des informations de son garant et du type de revenus déclarés.
* **Acceptation / Refus motivé** : Bouton d'acceptation de la candidature déclenchant la génération du contrat de bail PDF.

#### C. Suivi des Baux & Fiscalité Camerounaise
* **Génération & Télechargement du Bail PDF** : Modèles légaux révisés en droit civil (zone francophone) et common law (zone anglophone).
* **Tableau de Bord du Précompte sur Loyer** : Calculateur affichant Loyer Brut, Précompte Fisc (10%), et Net Bailleur, avec exportation de la fiche récapitulative annuelle pour la déclaration d'impôts.
* **Historique des Échéances & Quittances** : Visualisation des paiements perçus et émission de quittances PDF.

---

## 4. Staff / Modérateur Opérationnel (STAFF)

### 4.1 Profil & Objectif Principal
Le staff regroupe les équipes d'opérations locales et de modération de LocaDirect CM basées au Cameroun. Leur objectif est de garantir la qualité et la fraîcheur du catalogue d'annonces, de vérifier l'authenticité des pièces d'identité et d'instruire les litiges.

### 4.2 Valeur Ajoutée & Utilité
* **Contrôle Qualité & Anti-Fraude** : Bloque les fausses annonces, les arnaques aux frais de visite et les photos volées grâce aux algorithmes de hachage perceptuel (`phash`).
* **Résolution des Litiges en < 72h** : Garantit la confiance de la marketplace en remboursant les locataires lésés.

### 4.3 Étapes d'Intervention dans le Parcours
```
1. File de Modération Biens ➔ 2. Validation KYC (CNI/Selfie) ➔ 3. Instruction des Litiges ➔ 4. Déclenchement Remboursements ➔ 5. Sanction / Suspension d'Agent
```

### 4.4 Liste Exhaustive des Fonctionnalités à Implémenter

#### A. Back-Office de Modération des Annonces (`apps/admin`)
* **File d'Attente des Biens (`EN_VERIFICATION`)** : Interface de revue rapide des photos, de la cohérence du prix par rapport à la médiane du quartier, et de la géolocalisation.
* **Détection de Doublons (pHash)** : Alerte automatique en cas de photos identiques déjà enregistrées dans la base.
* **Validation / Rejet avec Motif** : Envoi automatique d'un SMS/WhatsApp à l'agent avec le motif du rejet (ex: *Photos floues, Prix aberrant*).

#### B. Vérification KYC (Loi n° 2024/017)
* **File de Validation des Documents d'Identité** : Contrôle de la correspondance entre CNI, Selfie, et titulaire du compte Mobile Money.
* **Journalisation du Consentement & Purge** : Programmation de la date de purge automatique des documents sensibles (`purge_le`).

#### C. Gestion des Litiges & Remboursements
* **Instruction des Contestations de Visite** : Consultation des logs GPS du check-in agent, des horodatages et des déclarations locataires.
* **Ordre de Remboursement Automatisé** : Reconstitution de l'écriture comptable et déclenchement du virement inverse via l'API PSP MoMo.

---

## 5. Administrateur Système (ADMIN)

### 5.1 Profil & Objectif Principal
L'administrateur système pilote la stratégie globale, la configuration économique, l'ouverture de nouvelles villes et le suivi de la santé financière de la plateforme.

### 5.2 Valeur Ajoutée & Utilité
* **Pilotage Multi-Villes** : Ouverture/fermeture dynamique de villes et paramétrage des seuils de liquidité.
* **Gestion des Grilles Tarifaires** : Ajustement des frais de visite et des taux de commission par ville sans modifier le code source.
* **Audot & Conformité Financière** : Consultation du Grand Livre comptable en partie double.

### 5.3 Liste Exhaustive des Fonctionnalités à Implémenter
* **Gestion des Villes & Quartiers** : Création de référentiels géo, tracé des contours géographiques et statut d'ouverture (`FERMEE`, `PRE_LANCEMENT`, `OUVERTE`).
* **Paramétrage Économique (`ville.parametres`)** : Configuration par ville des frais de visite (ex: 2 000 FCFA à Douala vs 1 500 FCFA à Bafoussam) et des taux de commission agent/plateforme.
* **Journal d'Audit Système (`JournalAudit`)** : Traçabilité complète des actions administratives et des modifications sensibles.
* **Tableau de Bord Métriques & KPIs** : Suivi du taux de fraîcheur du stock, du CAC par annonce vérifiée, et du taux de désintermédiation estimé.

---

## 6. Matrice Croisée des Parcours et Interactions

```
┌─────────────────┐       1. Ajoute Bien + Photos + Preuve       ┌─────────────────┐
│                 ├─────────────────────────────────────────────►│                 │
│      AGENT      │       4. Effectue Visite + Check-in GPS      │   PLATEFORME    │
│  (Démarcheur)   │◄─────────────────────────────────────────────┤  LOCADIRECT CM  │
└────────┬────────┘       5. Reçoit Commission MoMo              └────────▲────────┘
         │                                                                │
         │ 2. Mandat                                                      │ 3. Paie Frais Visite
         ▼                                                                │    (2000 FCFA MoMo)
┌─────────────────┐       6. Soumet Candidature & Dossier CNI    ┌────────┴────────┐
│    BAILLEUR     │◄─────────────────────────────────────────────┤    LOCATAIRE    │
│  (Propriétaire) ├─────────────────────────────────────────────►│   (Recherche)   │
└─────────────────┘       7. Valide Candidature & Reçoit Bail    └─────────────────┘
```

---

## Conclusion & Prochaines Étapes de Développement

Ce document sert de **cahier des spécifications fonctionnelles par rôle**. Toute nouvelle fonctionnalité ou écran développé dans les applications NestJS, Next.js ou Flutter doit se référer strictement aux périmètres décrits ci-dessus.
