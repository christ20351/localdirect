#!/bin/sh
# Applique le schéma à la base, exécuté par le service `api-migrate` du compose
# de production. Ce script tourne dans l'étage `build` de l'image : c'est le
# seul à disposer du CLI Prisma, de ts-node et du dossier prisma/.
#
# Il s'exécute jusqu'au bout puis rend la main ; l'API n'est démarrée qu'après
# sa sortie en code 0 (`service_completed_successfully`). Aucune migration ne
# peut donc s'appliquer pendant que l'API sert du trafic.
#
# AUCUN SEED ICI : la base de production reste vide (pas de villes de
# démonstration, pas d'annonces, pas de compte). L'amorçage du premier
# administrateur est une opération manuelle et explicite — voir docs/DEPLOY.md.
set -eu

echo "→ Migrations Prisma"
npx prisma migrate deploy

echo "✓ Schéma à jour"
