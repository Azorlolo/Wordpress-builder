# {{SITE_TITLE}}

Projet WordPress généré avec le script d'installation Tealforge.

---

## Stack technique

- **CMS** : WordPress
- **Templating** : Timber 2 et Twig
- **Thème** : `tealforge` (pages composées via ACF Pro Flexible Content)
- **Formulaires** : WPForms
- **Build assets** : Vite, CSS natif et JavaScript natif
- **Environnement local** : DDEV

---

## 1. Prérequis

Avant de reprendre ce projet sur un poste, assure-toi d'avoir installé :

- [Docker Desktop](https://docs.docker.com/desktop/setup/install/mac-install/)
- [DDEV](https://ddev.com)
- mkcert *(recommandé, pour les certificats HTTPS locaux)*
- Git

PHP, Composer, Node.js et WP-CLI ne sont pas à installer séparément : ils sont fournis par DDEV.

---

## 2. Cloner le projet

```bash
# Remplacer l'URL ci-dessous par celle du remote GitHub/GitLab une fois ajouté
git clone <URL_DU_REMOTE>
cd {{PROJECT_SLUG}}
```

---

## 3. Installer les dépendances

Démarrer l'environnement DDEV (nécessaire avant toute commande WP-CLI, Composer ou npm) :

```bash
ddev start
```

> **Démarrer Docker Desktop et attendre qu'il soit prêt avant `ddev start`.**

Installer les dépendances du thème :

```bash
ddev composer --working-dir=/var/www/html/web/wp-content/themes/tealforge install
ddev npm --prefix /var/www/html/web/wp-content/themes/tealforge install
bin/build
```

---

## 4. Configurer l'environnement

Le Core WordPress et `wp-config.php` ne sont pas versionnés (fichiers volumineux ou contenant des informations sensibles). Il faut donc les recréer à partir de zéro :

```bash
ddev wp core download --path=/var/www/html/web --locale=fr_FR --skip-content
ddev wp config create \
  --path=/var/www/html/web \
  --dbname=db --dbuser=db --dbpass=db --dbhost=db
```

La base de données et les médias ne sont pas non plus versionnés. Deux options ensuite :

- **Projet déjà en production/dev** : importer la base et les médias depuis l'environnement de référence avec WPvivid, après un backup (sens recommandé : `dev/prod -> local`) ;
- **Aucune base disponible** : réinstaller WordPress à vide (voir section suivante).

---

## 5. Recréer le compte administrateur

Le compte administrateur créé par le script d'installation d'origine **n'est pas versionné dans Git** (mot de passe généré aléatoirement, jamais stocké).

### Si une base a été importée (WPvivid)

Utiliser le compte administrateur présent dans la base importée, ou réinitialiser son mot de passe :

```bash
ddev wp user update {{ADMIN_USER}} --user_pass='TON_MOT_DE_PASSE' --path=/var/www/html/web
```

### Si aucune base n'est disponible (installation neuve)

```bash
ddev wp core install \
  --path=/var/www/html/web \
  --url=https://{{DDEV_DOMAIN}} \
  --title="{{SITE_TITLE}}" \
  --admin_user={{ADMIN_USER}} \
  --admin_password='TON_MOT_DE_PASSE' \
  --admin_email={{ADMIN_EMAIL}} \
  --skip-email
ddev wp rewrite structure '/%postname%/' --path=/var/www/html/web
ddev wp rewrite flush --path=/var/www/html/web
```

### Recommandation sur le mot de passe

Utilise un mot de passe de 18 caractères minimum, contenant au moins :

- Une majuscule
- Une minuscule
- Un chiffre
- Un caractère spécial

### Connexion

```text
Utilisateur  : {{ADMIN_USER}}
Email        : {{ADMIN_EMAIL}}
Mot de passe : TON_MOT_DE_PASSE
```

---

## 6. Lancer l'environnement de développement local

```bash
ddev launch
```

> DDEV gère déjà le serveur HTTP, la base de données et les certificats HTTPS locaux.

Pour arrêter l'environnement :

```bash
ddev stop
```

---

## 7. Accès au projet

| Service        | URL |
|----------------|-----|
| Site           | `https://{{DDEV_DOMAIN}}` |
| Administration | `https://{{DDEV_DOMAIN}}/wp-admin` |

---

## 8. Git

La branche principale du projet est :

```text
main
```

Pour récupérer les derniers changements :

```bash
git pull
```

Pour envoyer tes changements :

```bash
bin/commit "Message clair"
bin/push
```

### Fichiers non versionnés

Les éléments suivants sont volontairement exclus du dépôt (`.gitignore`) car sensibles, générés ou propres à chaque poste :

- le Core WordPress (hors thème) ;
- `web/wp-config.php` ;
- la base de données et les médias (`wp-content/uploads`) ;
- les plugins tiers (`wp-content/plugins`) ;
- `deploy.local.env`.

Chaque développeur doit donc reconfigurer son environnement et recréer sa base locale après un clone (voir sections 4 et 5).

---

## 9. Notes complémentaires

- Ce projet a été initialisé à partir du boilerplate WordPress Tealforge.
- Le thème actif est **`tealforge`**, les pages sont composées via des sections ACF Flexible Content.
- Les plugins tiers suivants doivent être installés manuellement depuis l'administration WordPress (licences requises, non versionnés) : ACF Pro, WPForms, WPvivid, WP-Optimize, un plugin de maintenance, All-In-One Security / AIOS.
- Commandes utiles : `bin/status`, `bin/check`, `bin/build`, `bin/ci-check`, `bin/commit`, `bin/push`, `bin/deploy-theme`.
- Pour toute question sur la structure du projet ou les conventions utilisées, se référer à [AGENTS.md](AGENTS.md), [PROJECT.md](PROJECT.md) et [docs/](docs).