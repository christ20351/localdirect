# syntax=docker/dockerfile:1.7
#
# Image de l'API NestJS.
#
# Base Debian slim et non Alpine : bcrypt est un module natif dont les binaires
# précompilés ciblent la glibc. Sur musl, npm retomberait sur une compilation
# depuis les sources à chaque build.
#
# Trois étages utiles :
#   deps      → dépendances complètes (dev incluses) + chaîne de compilation
#   build     → client Prisma généré + code compilé. Sert AUSSI d'image de
#               migration : c'est le seul étage à contenir le CLI Prisma,
#               ts-node et le dossier prisma/.
#   runner    → image d'exécution, dépendances de production seules.

# --------------------------------------------------------------------------
FROM node:24-bookworm-slim AS deps
WORKDIR /app

# openssl : requis par les moteurs Prisma.
# python3/make/g++ : filet de sécurité si aucun binaire bcrypt précompilé ne
# correspond à la plateforme de build.
RUN apt-get update \
 && apt-get install -y --no-install-recommends openssl ca-certificates python3 make g++ \
 && rm -rf /var/lib/apt/lists/*

COPY package.json package-lock.json ./
RUN npm ci

# --------------------------------------------------------------------------
FROM deps AS build
WORKDIR /app

COPY . .

# `prisma generate` doit précéder `nest build` : le code importe les types du
# client généré.
RUN npx prisma generate \
 && npm run build \
 && chmod +x docker-migrate.sh

# --------------------------------------------------------------------------
# Dépendances de production seules, élaguées depuis `deps` pour que les modules
# natifs déjà compilés (bcrypt) soient réutilisés tels quels.
FROM deps AS prod-deps
WORKDIR /app
RUN npm prune --omit=dev

# --------------------------------------------------------------------------
FROM node:24-bookworm-slim AS runner
WORKDIR /app

RUN apt-get update \
 && apt-get install -y --no-install-recommends openssl ca-certificates curl \
 && rm -rf /var/lib/apt/lists/*

ENV NODE_ENV=production \
    PORT=3000

COPY --from=prod-deps --chown=node:node /app/node_modules ./node_modules
# Le client Prisma est généré dans `build` : `prisma generate` est un
# devDependency, absent de l'arbre de production élagué.
COPY --from=build --chown=node:node /app/node_modules/.prisma ./node_modules/.prisma
COPY --from=build --chown=node:node /app/node_modules/@prisma/client ./node_modules/@prisma/client
COPY --from=build --chown=node:node /app/dist ./dist
COPY --chown=node:node package.json ./

# Les fichiers déposés (photos de biens, CNI, baux PDF) atterrissent ici, sous
# un volume Docker. Le dossier doit exister ET appartenir à `node` AVANT le
# montage, sinon le volume hérite de root et l'API ne peut plus y écrire.
RUN mkdir -p /app/uploads/medias /app/uploads/documents /app/uploads/baux \
 && chown -R node:node /app/uploads

USER node
EXPOSE 3000

# `/api/v1` n'est mappé par aucun contrôleur : la sonde vise `/api/v1/villes`,
# route publique sans authentification, qui répond 200 même sur base vide.
HEALTHCHECK --interval=30s --timeout=5s --start-period=20s --retries=3 \
  CMD curl -fsS -o /dev/null http://127.0.0.1:3000/api/v1/villes || exit 1

CMD ["node", "dist/main"]
