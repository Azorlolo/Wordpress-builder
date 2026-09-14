# Script d'installation WordPress + Timber (boilerplate Tealforge)

Crée en une commande un projet WordPress + Timber/Twig + ACF, servi par DDEV, avec un compte admin, le thème `tealforge` buildé, et un premier commit Git prêt à être poussé sur GitLab/GitHub.

---

## Dépendances nécessaires

Avant de lancer le script, assure-toi d'avoir installé :

- Docker Desktop
- DDEV
- mkcert *(recommandé, pour les certificats HTTPS locaux)*
- Git

👉 Liens de téléchargement, commandes d'installation et points d'attention : voir la section [Dépendances](#dépendances) tout en bas de ce README.

Le script vérifie lui-même leur présence au démarrage (et que Docker Desktop est bien lancé) et s'arrête avec un message clair si l'une d'elles manque — mais installer tout en amont évite les allers-retours.

PHP, Composer, Node.js et WP-CLI ne sont **pas** à installer sur le poste : ils sont fournis par DDEV.

---

## Télécharger le dossier du script

Le dépôt contient un dossier par système d'exploitation (`mac-os`, `windows`, etc.). Télécharge celui qui correspond à ton OS.

⚠️ **Il est important de télécharger le dossier entier, et non pas uniquement le fichier `new-wordpress.sh`.** Le script a besoin du sous-dossier `templates/` (qui contient le README injecté dans chaque projet généré) situé juste à côté de lui. Si tu ne récupères que le `.sh` isolé, le script s'arrêtera dès son lancement avec une erreur `Template README introuvable`.

Structure attendue une fois téléchargée :

```text
mac-os/
├── new-wordpress.sh
└── templates/
    └── README.md
```

---

## Installation du script

⚠️ Remplace le chemin ci-dessous par le chemin complet **de ton propre script** dans les 3 commandes suivantes.

Exemple de chemin utilisé ici :

```text
/Users/tealforge/Dev/Scripts/mac-os/new-wordpress.sh
```

##

Lancer la commande dans un terminal quelconque

```bash
chmod +x /Users/tealforge/Dev/Scripts/mac-os/new-wordpress.sh
```

```bash
nano ~/.zshrc
```

Ajouter dans le fichier :

```bash
alias wordpress-tealforge="/Users/tealforge/Dev/Scripts/mac-os/new-wordpress.sh"
```

```bash
source ~/.zshrc
```

---

## Créer un projet

⚠️ la commande est a faire dans **ton repertoire de projet dev**

Exemple de chemin utilisé ici :

```text
/Users/tealforge/Dev
```

##

```bash
cd /Users/tealforge/Dev
wordpress-tealforge
```

Le script demande :

```text
Nom du projet (dossier + site DDEV) :
Titre du site WordPress :
```

Si tu ne saisis pas de titre, celui-ci reprend le nom du projet.

Le script clone ensuite le boilerplate, supprime le remote d'origine, installe WordPress, build le thème `tealforge`, puis affiche l'utilisateur, l'email et le mot de passe admin générés — attends la confirmation avant de continuer.

---

## Relier le projet à un dépôt distant

Créer un projet **vide** sur GitLab/GitHub (sans README, sans `.gitignore`, sans licence).

⚠️ Remplace `git@gitlab.com:organisation/mon-projet.git` par l'URL SSH ou HTTPS de **ton propre projet**.

```bash
cd /Users/tealforge/Dev/mon-projet

git remote add origin git@gitlab.com:organisation/mon-projet.git

git remote -v

git push -u origin main
```

Les envois suivants se font simplement avec :

```bash
git push
```

---

## Lancer le projet

```bash
cd /Users/tealforge/Dev/mon-projet
ddev start
ddev launch
```

```text
ddev stop
```
pour arrêter l'environnement.

---

## Informations sur le projet généré

### Accès

| Service        | URL |
|----------------|-----|
| Site           | `https://mon-projet.ddev.site` |
| Administration | `https://mon-projet.ddev.site/wp-admin` |

### Compte administrateur

- Utilisateur : `tf-admin`
- Email : `admin@tealforge.com`
- Mot de passe : généré aléatoirement (18 caractères, affiché une seule fois par le script)

### Git

- Branche : `main`
- Premier commit : `Initialisation du site WordPress + Timber - Conçu par Tealforge`
- Aucun remote ajouté automatiquement
- `web/wp-config.php` et `deploy.local.env` sont ignorés par Git

### README du projet généré

Le script remplace le README du boilerplate par celui de `templates/README.md`, avec les variables du projet déjà injectées (titre, domaine DDEV, identifiant/email admin). Ce README explique notamment comment recréer l'environnement et le compte administrateur sur un autre poste après un clone.

### Développement

Commandes principales fournies par le boilerplate :

```bash
bin/build      # compile les assets Vite dans dist/
bin/status     # état du projet
bin/check      # vérifications locales
bin/ci-check   # vérifie Git, PHP, npm, build Vite et le manifest
bin/commit     # commit simplifié
bin/push       # push simplifié
bin/deploy-theme  # prépare l'archive et affiche les commandes de déploiement
```

### Plugins tiers à installer manuellement

Non fournis par le script (licences requises), à installer depuis l'administration WordPress :

- ACF Pro
- WPForms
- WPvivid
- WP-Optimize
- Un plugin de maintenance
- All-In-One Security / AIOS

### Autres commandes utiles

Modifier un remote existant :

```bash
git remote set-url origin git@gitlab.com:organisation/mon-projet.git
```

Supprimer un remote :

```bash
git remote remove origin
```

Vérifier la branche active :

```bash
git branch
```

---

> ℹ️ Pour reprendre le projet sur un autre poste (base, médias, plugins), voir la section « Reprise du projet sur un autre poste » du README généré dans le projet (`templates/README.md`).

---

## Dépendances

Détail de chaque dépendance : à quoi elle sert, comment l'installer, comment vérifier qu'elle est bien reconnue, et les pièges fréquents.

### Docker Desktop

Fait tourner les conteneurs DDEV (WordPress, base de données, etc.).

- Téléchargement : [https://docs.docker.com/desktop/setup/install/mac-install/](https://docs.docker.com/desktop/setup/install/mac-install/)
- Installation : télécharger le `.dmg`, glisser Docker dans `/Applications`, puis **ouvrir l'application au moins une fois** et attendre qu'elle indique qu'elle est prête.
- Vérifier :
  ```bash
  docker --version
  docker info
  ```

⚠️ **Piège fréquent** : lancer `ddev start` alors que Docker Desktop n'est pas encore complètement démarré. Le script vérifie ce point et s'arrête avec un message clair si Docker n'est pas prêt — attends toujours l'icône "Docker Desktop is running" avant de relancer.

### DDEV

Gère l'environnement local (PHP, MySQL, WP-CLI, Composer, Node) sans rien installer sur le poste.

- Installation via Homebrew :
  ```bash
  brew install ddev/ddev/ddev
  ```
- Vérifier :
  ```bash
  ddev version
  ```

### mkcert

Génère des certificats HTTPS locaux valides pour les sites `.ddev.site`.

- Installation via Homebrew :
  ```bash
  brew install mkcert
  mkcert -install
  ```
- Vérifier :
  ```bash
  mkcert -version
  ```

Optionnel mais recommandé : sans lui, DDEV peut afficher des avertissements de certificat non fiable dans le navigateur.

### PHP, Composer, Node.js, WP-CLI

Fournis et gérés automatiquement par DDEV — aucune installation séparée n'est nécessaire.

- Vérifier (une fois un projet DDEV démarré) :
  ```bash
  ddev exec php --version
  ddev composer --version
  ddev npm --version
  ddev wp --version
  ```

### Git

Nécessaire pour cloner le boilerplate, l'initialisation du dépôt local et l'envoi vers GitLab/GitHub.

- Installation via Homebrew :
  ```bash
  brew install git
  ```
- Téléchargement alternatif : [https://git-scm.com/downloads](https://git-scm.com/downloads)
- Vérifier :
  ```bash
  git --version
  ```
- Identité Git requise avant de lancer le script :
  ```bash
  git config --global user.name "Prénom Nom"
  git config --global user.email "email@tealforge.com"
  ```
- Accès SSH requis pour cloner le boilerplate :
  ```bash
  ssh -T git@github.com
  ```

### Après avoir tout installé

Une fois les dépendances installées, vérifie-les toutes d'un coup avant de lancer le script :

```bash
docker --version
docker info
ddev version
mkcert -version
git --version
```

Si l'une de ces commandes échoue avec `command not found` **alors que tu viens d'installer l'outil correspondant**, ferme et rouvre le terminal avant de relancer le script.