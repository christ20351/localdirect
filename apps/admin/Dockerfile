# syntax=docker/dockerfile:1.7
#
# Image du back-office Next.js.
#
# S'appuie sur `output: 'standalone'` (voir next.config.ts) : Next trace les
# modules réellement importés et produit un serveur autonome. L'image finale ne
# contient donc aucun node_modules complet.

# --------------------------------------------------------------------------
FROM node:24-bookworm-slim AS deps
WORKDIR /app
COPY package.json package-lock.json ./
RUN npm ci

# --------------------------------------------------------------------------
FROM node:24-bookworm-slim AS build
WORKDIR /app
COPY --from=deps /app/node_modules ./node_modules
COPY . .

# Les variables NEXT_PUBLIC_* sont figées dans le bundle au moment du build,
# pas lues à l'exécution. La valeur par défaut est une URL *relative* : le
# back-office et l'API sont servis sur la même origine par nginx, donc le
# navigateur résout `/api/v1/...` contre le domaine courant. L'image reste
# ainsi indépendante du nom de domaine.
ARG NEXT_PUBLIC_API_URL=/api/v1
ENV NEXT_PUBLIC_API_URL=$NEXT_PUBLIC_API_URL
ENV NEXT_TELEMETRY_DISABLED=1

RUN npm run build

# --------------------------------------------------------------------------
FROM node:24-bookworm-slim AS runner
WORKDIR /app

RUN apt-get update \
 && apt-get install -y --no-install-recommends curl \
 && rm -rf /var/lib/apt/lists/*

ENV NODE_ENV=production \
    NEXT_TELEMETRY_DISABLED=1 \
    PORT=3000 \
    HOSTNAME=0.0.0.0

COPY --from=build --chown=node:node /app/public ./public
COPY --from=build --chown=node:node /app/.next/standalone ./
# Le mode standalone ne recopie pas les fichiers statiques : ils doivent être
# placés à côté du serveur pour être servis sous /_next/static.
COPY --from=build --chown=node:node /app/.next/static ./.next/static

USER node
EXPOSE 3000

HEALTHCHECK --interval=30s --timeout=5s --start-period=20s --retries=3 \
  CMD curl -fsS http://127.0.0.1:3000/login || exit 1

CMD ["node", "server.js"]
