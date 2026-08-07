# Raccordement Traefik → VM

## Le problème

`app.koryx.net` résout correctement vers `108.181.196.201`, mais cette adresse
n'appartient pas à la VM. La VM n'a qu'une adresse privée :

```
$ ip -4 -br addr        # depuis la VM
lo         UNKNOWN   127.0.0.1/8
enp16s0    UP        192.168.122.40/24     ← seule adresse de la VM
docker0    DOWN      172.17.0.1/16

$ ip route
default via 192.168.122.1 dev enp16s0
```

Les ports 80 et 443 publics sont détenus par un **Traefik** placé devant la VM :

```
$ curl -I http://108.181.196.201/
HTTP/1.1 404 Not Found
Content-Type: text/plain; charset=utf-8
X-Content-Type-Options: nosniff        ← 404 par défaut d'un serveur Go

$ openssl s_client -connect 108.181.196.201:443 -servername app.koryx.net
subject = CN=TRAEFIK DEFAULT CERT
SAN     = d28f2a9c….bb72727d….traefik.default
```

Le certificat auto-signé `*.traefik.default` est celui que Traefik sert quand
**aucun routeur ne correspond à l'hôte demandé**. Le suffixe `.default` est le
namespace Kubernetes : le frontal est très probablement un **k3s**, qui embarque
Traefik comme ingress controller par défaut.

Preuve que la VM n'est pas en cause — depuis la VM elle-même :

| Requête | Réponse |
|---|---|
| `curl -H 'Host: app.koryx.net' http://127.0.0.1/` | **502** — nginx répond, l'upstream est en panne |
| `curl http://108.181.196.201/` | **404 page not found** — Traefik, nginx n'a rien vu |

`/var/log/nginx/access.log` ne contient aucune ligne 404 : le trafic public
n'atteint jamais ce nginx.

Seul le port **10051 → VM:22** est redirigé vers la VM. Rien d'autre n'entre.

## Ce qu'il reste à faire

Déclarer sur le frontal une route `Host(app.koryx.net)` → `192.168.122.40:80`.
Deux variantes selon la façon dont Traefik est configuré.

### Variante A — k3s (la plus probable)

```sh
kubectl apply -f k3s-locadirect.yaml
```

Le fichier déclare un `Service` sans sélecteur plus un `EndpointSlice` pointant
sur l'adresse privée de la VM, un `IngressRoute` sur le point d'entrée
`websecure`, et une redirection HTTP → HTTPS.

Vérifier ensuite que le certificat Let's Encrypt est bien émis :

```sh
kubectl -n default describe ingressroute locadirect
kubectl -n kube-system logs deploy/traefik | grep -i acme
```

Si aucun `certResolver` n'est configuré sur ce Traefik, Traefik continuera de
servir `TRAEFIK DEFAULT CERT`. Il faut alors soit activer un resolveur ACME sur
l'installation (`--certificatesresolvers.le.acme.*`), soit fournir le
certificat via un `Secret` TLS et le référencer dans `tls.secretName`.

### Variante B — Traefik autonome, provider fichier

Déposer `traefik-dynamic-locadirect.yml` dans le répertoire surveillé par le
provider fichier (souvent `/etc/traefik/dynamic/`). Traefik le recharge à chaud,
aucun redémarrage nécessaire.

## Vérification, dans les deux cas

```sh
curl -I https://app.koryx.net/            # 200, page de connexion du back-office
curl -s https://app.koryx.net/api/v1      # réponse de l'API
```

Si le résultat reste `404 page not found`, la route n'est pas prise en compte
par Traefik. S'il devient `502` ou `504`, la route fonctionne et le problème
s'est déplacé vers la VM (nginx ou conteneurs) — c'est un progrès.
