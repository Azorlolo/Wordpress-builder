#!/usr/bin/env bash

set -Eeuo pipefail

# ============================================================
# CONFIGURATION
# ============================================================

BOILERPLATE_REPO_URL="git@github.com:ZeFranck69/boilerplate-wordpress-tealforge.git"

WP_LOCALE="fr_FR"
ADMIN_USER="tf-admin"
ADMIN_EMAIL="dev@tealforge.local"
PASSWORD_LENGTH=18
GIT_INITIAL_COMMIT="Initialisation du site WordPress + Timber - Conçu par Tealforge"

WP_PATH="web"
THEME_PATH="${WP_PATH}/wp-content/themes/tealforge"

CURRENT_STEP="Initialisation"

# ============================================================
# COULEURS
# ============================================================

RESET='\033[0m'
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
DIM='\033[2m'

# ============================================================
# LOGS
# ============================================================

title() {
    echo
    echo -e "${BOLD}============================================================${RESET}"
    echo -e "${BOLD} $1${RESET}"
    echo -e "${BOLD}============================================================${RESET}"
    echo
}

step() {
    CURRENT_STEP="$1"

    echo
    echo -e "${BLUE}${BOLD}▶ $1${RESET}"
    echo
}

info() {
    echo -e "  ${BLUE}•${RESET} $1"
}

success() {
    echo -e "  ${GREEN}✓${RESET} $1"
}

warning() {
    echo -e "  ${YELLOW}!${RESET} $1"
}

error() {
    echo
    echo -e "${RED}${BOLD}✗ ERREUR${RESET}"
    echo -e "  ${RED}$1${RESET}"
    echo
    exit 1
}

separator() {
    echo -e "${DIM}  ----------------------------------------------------------${RESET}"
}

# ============================================================
# GESTION DES ERREURS
# ============================================================

on_error() {
    local exit_code=$?
    local line_number=$1

    echo
    echo -e "${RED}${BOLD}✗ INSTALLATION INTERROMPUE${RESET}"
    echo
    echo -e "  Étape : ${CURRENT_STEP}"
    echo -e "  Ligne : ${line_number}"
    echo -e "  Code  : ${exit_code}"
    echo
    echo -e "${YELLOW}  Consulte le message affiché juste au-dessus.${RESET}"
    echo

    exit "$exit_code"
}

trap 'on_error $LINENO' ERR

# ============================================================
# OUTILS SED PORTABLES (macOS / Linux)
# ============================================================

if [[ "${OSTYPE:-}" == darwin* ]]; then
    SED_INPLACE=(-i '')
else
    SED_INPLACE=(-i)
fi

# ============================================================
# MOT DE PASSE
# ============================================================

random_char() {
    local chars="$1"
    local chars_length=${#chars}
    local random_number
    local index

    random_number=$(od -An -N2 -tu2 /dev/urandom | tr -d ' ')
    index=$((random_number % chars_length))

    printf '%s' "${chars:index:1}"
}

generate_password() {
    local uppercase='ABCDEFGHIJKLMNOPQRSTUVWXYZ'
    local lowercase='abcdefghijklmnopqrstuvwxyz'
    local digits='0123456789'
    local specials='!@#%^&*_-+='
    local all_chars="${uppercase}${lowercase}${digits}${specials}"

    local password_chars=()
    local i
    local j
    local tmp
    local random_number

    # Au moins une majuscule
    password_chars+=("$(random_char "$uppercase")")

    # Au moins une minuscule
    password_chars+=("$(random_char "$lowercase")")

    # Au moins un chiffre
    password_chars+=("$(random_char "$digits")")

    # Au moins un caractère spécial
    password_chars+=("$(random_char "$specials")")

    # Complète jusqu'à PASSWORD_LENGTH caractères
    for ((i=4; i<PASSWORD_LENGTH; i++)); do
        password_chars+=("$(random_char "$all_chars")")
    done

    # Mélange Fisher-Yates
    for ((i=PASSWORD_LENGTH-1; i>0; i--)); do
        random_number=$(od -An -N2 -tu2 /dev/urandom | tr -d ' ')
        j=$((random_number % (i + 1)))

        tmp="${password_chars[i]}"
        password_chars[i]="${password_chars[j]}"
        password_chars[j]="$tmp"
    done

    printf '%s' "${password_chars[@]}"
}

# ============================================================
# VÉRIFICATION D'UNE COMMANDE
# ============================================================

check_command() {
    local command_name="$1"
    local label="$2"
    local install_hint="$3"
    local version

    info "Vérification de $label..."

    if ! command -v "$command_name" >/dev/null 2>&1; then
        error "$label n'est pas installé ou n'est pas disponible dans le PATH.

Installation :
$install_hint"
    fi

    version=$("$command_name" --version 2>/dev/null | head -n 1 || true)

    if [ -n "$version" ]; then
        success "$label : $version"
    else
        success "$label détecté"
    fi
}

check_docker_running() {
    info "Vérification que Docker Desktop est démarré..."

    if ! docker info >/dev/null 2>&1; then
        error "Docker Desktop ne semble pas démarré.

Démarre Docker Desktop, attends qu'il indique qu'il est prêt, puis relance ce script."
    fi

    success "Docker Desktop est démarré"
}

check_github_ssh_access() {
    local ssh_output

    info "Vérification de l'accès SSH à GitHub..."

    # 'set +e' seul ne suffit pas : le trap ERR se déclenche même avec
    # 'set +e' pour une simple commande qui échoue. Seul '|| true' (ou un
    # test if) empêche réellement le trap de se déclencher ici.
    ssh_output=$(ssh -o BatchMode=yes -o StrictHostKeyChecking=accept-new -T git@github.com 2>&1) || true

    if echo "$ssh_output" | grep -qi "successfully authenticated"; then
        success "Accès SSH à GitHub confirmé"
        return
    fi

    error "Impossible de s'authentifier en SSH sur GitHub (git@github.com).

Sortie de 'ssh -T git@github.com' :
${ssh_output}

Vérifications possibles :

1. Une clé SSH existe-t-elle et est-elle chargée ?
   ls -al ~/.ssh
   ssh-add -l

2. Si aucune clé n'existe, en générer une puis l'ajouter sur GitHub :
   ssh-keygen -t ed25519 -C \"ton-email@tealforge.com\"
   eval \"\$(ssh-agent -s)\"
   ssh-add ~/.ssh/id_ed25519
   pbcopy < ~/.ssh/id_ed25519.pub
   -> GitHub > Settings > SSH and GPG keys > New SSH key

3. La clé chargée dans l'agent est-elle bien celle enregistrée sur GitHub ?
   Vérifier qu'aucun ~/.ssh/config ne force une autre IdentityFile pour
   'github.com', et que le contenu de ~/.ssh/id_ed25519.pub correspond
   bien à une clé listée dans GitHub > Settings > SSH and GPG keys.

4. As-tu bien accès au dépôt du boilerplate (droits collaborateur, ou SSO
   d'organisation à autoriser pour cette clé) ?

Relance ce script une fois l'accès confirmé avec :
   ssh -T git@github.com"
}

# ============================================================
# DÉMARRAGE
# ============================================================

title "INSTALLATION WORDPRESS + TIMBER (BOILERPLATE TEALFORGE)"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATE_README="$SCRIPT_DIR/templates/README.md"

info "Script lancé"
info "Répertoire de création : $(pwd)"
info "Script : ${BASH_SOURCE[0]}"

echo

if [ ! -f "$TEMPLATE_README" ]; then
    error "Template README introuvable : $TEMPLATE_README

Ce script a besoin du sous-dossier 'templates/' situé juste à côté de lui.
Assure-toi d'avoir téléchargé le dossier entier (mac-os/) et non uniquement new-wordpress.sh."
fi

success "Template README trouvé : $TEMPLATE_README"

success "Initialisation terminée"

# ============================================================
# 1. DÉPENDANCES
# ============================================================

step "1/11 — Vérification des dépendances"

check_command git "Git" "brew install git  (ou : https://git-scm.com/downloads)"
check_command docker "Docker" "https://docs.docker.com/desktop/setup/install/mac-install/"
check_command ddev "DDEV" "brew install ddev/ddev/ddev"

if command -v mkcert >/dev/null 2>&1; then
    success "mkcert détecté"
else
    warning "mkcert n'est pas détecté (recommandé pour les certificats HTTPS locaux)."
    info "Installation : brew install mkcert && mkcert -install"
fi

info "Vérification de l'identité Git..."

GIT_USER_NAME=$(git config --get user.name || true)
GIT_USER_EMAIL=$(git config --get user.email || true)

if [ -z "$GIT_USER_NAME" ] || [ -z "$GIT_USER_EMAIL" ]; then
    error "L'identité Git n'est pas configurée.

Configure-la avec :

git config --global user.name \"Prénom Nom\"
git config --global user.email \"email@tealforge.com\"

Puis relance le script."
fi

success "Identité Git : $GIT_USER_NAME <$GIT_USER_EMAIL>"

check_docker_running
check_github_ssh_access

echo
success "Toutes les dépendances nécessaires sont disponibles"

info "PHP, Composer, Node.js et WP-CLI seront utilisés via DDEV : aucune installation locale requise."

# ============================================================
# 2. CONFIGURATION DU PROJET
# ============================================================

step "2/11 — Configuration du projet"

info "Le projet sera créé dans : $(pwd)"
echo

while true; do
    read -rp "  Nom du projet (dossier + site DDEV) : " PROJECT_NAME

    if [ -z "$PROJECT_NAME" ]; then
        warning "Le nom du projet est obligatoire."
        continue
    fi

    PROJECT_SLUG=$(echo "$PROJECT_NAME" \
        | tr '[:upper:]' '[:lower:]' \
        | sed 's/ /-/g' \
        | sed 's/[^a-z0-9._-]//g')

    if [ -z "$PROJECT_SLUG" ]; then
        warning "Le nom fourni n'est pas valide."
        continue
    fi

    if [ -e "$PROJECT_SLUG" ]; then
        error "Le dossier '$PROJECT_SLUG' existe déjà dans $(pwd)."
    fi

    break
done

echo

read -rp "  Titre du site WordPress [${PROJECT_NAME}] : " SITE_TITLE

if [ -z "$SITE_TITLE" ]; then
    SITE_TITLE="$PROJECT_NAME"
fi

DDEV_DOMAIN="${PROJECT_SLUG}.ddev.site"

echo
separator
echo

echo -e "  Projet          : ${BOLD}$PROJECT_NAME${RESET}"
echo -e "  Dossier         : ${BOLD}$PROJECT_SLUG${RESET}"
echo -e "  Titre du site   : ${BOLD}$SITE_TITLE${RESET}"
echo -e "  Locale WP       : ${BOLD}$WP_LOCALE${RESET}"
echo -e "  URL DDEV        : ${BOLD}https://$DDEV_DOMAIN${RESET}"

echo
separator

# ============================================================
# 3. COMPTE ADMIN
# ============================================================

step "3/11 — Génération du compte administrateur"

info "Génération d'un mot de passe sécurisé de $PASSWORD_LENGTH caractères..."

ADMIN_PASSWORD="$(generate_password)"

success "Mot de passe généré"

echo
separator
echo

echo -e "  ${BOLD}COMPTE ADMINISTRATEUR WORDPRESS${RESET}"
echo
echo -e "  Utilisateur : ${GREEN}${ADMIN_USER}${RESET}"
echo -e "  Email       : ${GREEN}${ADMIN_EMAIL}${RESET}"
echo -e "  Mot de passe: ${GREEN}${ADMIN_PASSWORD}${RESET}"

echo
separator
echo

while true; do
    read -rp "  As-tu sauvegardé le mot de passe ? [oui/non] : " PASSWORD_SAVED

    case "$PASSWORD_SAVED" in

        oui|o|yes|y|OUI|YES|Oui|Yes)
            success "Mot de passe confirmé comme sauvegardé"
            break
            ;;

        non|n|no|N|NON|NO|Non|No)
            echo
            warning "Sauvegarde le mot de passe avant de continuer."
            echo
            echo -e "  Mot de passe : ${GREEN}${ADMIN_PASSWORD}${RESET}"
            echo
            ;;

        *)
            warning "Réponds par oui ou non."
            ;;

    esac
done

# ============================================================
# 4. CLONAGE DU BOILERPLATE + DÉSYNCHRONISATION
# ============================================================

step "4/11 — Clonage du boilerplate"

info "Clonage de $BOILERPLATE_REPO_URL"
info "Dossier cible : $(pwd)/$PROJECT_SLUG"

echo

git clone "$BOILERPLATE_REPO_URL" "$PROJECT_SLUG"

echo

success "Boilerplate cloné"

cd "$PROJECT_SLUG"

success "Répertoire courant : $(pwd)"

info "Désynchronisation du remote d'origine (pour ne pas impacter le boilerplate)..."

git remote remove origin

success "Remote 'origin' du boilerplate supprimé"

info "Préparation du fichier de projet PROJECT.md..."

cp PROJECT.md.example PROJECT.md

success "PROJECT.md créé depuis PROJECT.md.example"

# ============================================================
# 5. CONFIGURATION DDEV
# ============================================================

step "5/11 — Configuration de DDEV"

DDEV_CONFIG=".ddev/config.yaml"

if [ ! -f "$DDEV_CONFIG" ]; then
    error "Fichier introuvable : $DDEV_CONFIG"
fi

info "Application du nom de projet DDEV : $PROJECT_SLUG"

sed "${SED_INPLACE[@]}" \
    -E "s/^name:.*/name: ${PROJECT_SLUG}/" \
    "$DDEV_CONFIG"

success "Nom du projet DDEV configuré : $PROJECT_SLUG"

# ============================================================
# 6. WORDPRESS
# ============================================================

step "6/11 — Installation de WordPress"

info "Démarrage de DDEV..."

echo

ddev start

echo

success "DDEV démarré"

info "Téléchargement du Core WordPress (locale : $WP_LOCALE)..."

ddev wp core download --path=/var/www/html/${WP_PATH} --locale="$WP_LOCALE" --skip-content

success "Core WordPress téléchargé"

info "Création de wp-config.php..."

# DDEV génère automatiquement un wp-config.php au démarrage lorsque le type
# de projet est 'wordpress' (quickstart intégré) : --force permet de
# l'écraser proprement plutôt que d'échouer si le fichier existe déjà.
ddev wp config create \
    --path=/var/www/html/${WP_PATH} \
    --dbname=db --dbuser=db --dbpass=db --dbhost=db \
    --force

success "wp-config.php créé"

info "Installation de WordPress..."

echo

ddev wp core install \
    --path=/var/www/html/${WP_PATH} \
    --url="https://${DDEV_DOMAIN}" \
    --title="${SITE_TITLE}" \
    --admin_user="${ADMIN_USER}" \
    --admin_password="${ADMIN_PASSWORD}" \
    --admin_email="${ADMIN_EMAIL}" \
    --skip-email

echo

success "WordPress installé"

info "Configuration des permaliens..."

ddev wp rewrite structure '/%postname%/' --path=/var/www/html/${WP_PATH}
ddev wp rewrite flush --path=/var/www/html/${WP_PATH}

success "Permaliens configurés"

# ============================================================
# 7. THÈME ET BUILD
# ============================================================

step "7/11 — Installation du thème tealforge"

info "Installation des dépendances Composer du thème..."

echo

ddev composer --working-dir=/var/www/html/${THEME_PATH} install

echo

success "Dépendances Composer installées"

info "Installation des dépendances npm du thème..."

echo

ddev npm --prefix /var/www/html/${THEME_PATH} install

echo

success "Dépendances npm installées"

info "Build des assets (Vite)..."

echo

bin/build

echo

success "Assets construits (dist/)"

info "Activation du thème tealforge..."

ddev wp theme activate tealforge --path=/var/www/html/${WP_PATH}

success "Thème tealforge activé"

echo

warning "Les plugins tiers ne sont pas installés automatiquement (licences requises)."
info "À installer manuellement depuis l'administration WordPress :"
info "  - ACF Pro"
info "  - WPForms"
info "  - WPvivid"
info "  - WP-Optimize"
info "  - Un plugin de maintenance"
info "  - All-In-One Security / AIOS"

# ============================================================
# 8. VÉRIFICATION
# ============================================================

step "8/11 — Vérification finale"

info "Vérification de l'installation WordPress..."

if ! ddev wp core is-installed --path=/var/www/html/${WP_PATH} >/dev/null 2>&1; then
    error "WordPress ne semble pas correctement installé."
fi

success "WordPress opérationnel"

info "Vérification du thème actif..."

ACTIVE_THEME=$(ddev wp theme list --status=active --field=name --path=/var/www/html/${WP_PATH} 2>/dev/null | tr -d '\r')

if [ "$ACTIVE_THEME" != "tealforge" ]; then
    error "Le thème actif n'est pas 'tealforge' (actif : ${ACTIVE_THEME:-aucun})."
fi

success "Thème actif : tealforge"

info "Vérification du build Vite (manifest)..."

if [ -f "${THEME_PATH}/dist/manifest.json" ]; then
    success "Manifest Vite trouvé (dist/manifest.json)"
else
    warning "Manifest Vite introuvable, vérifier bin/build"
fi

if [ -x "bin/ci-check" ]; then
    info "Exécution de bin/ci-check..."
    echo
    bin/ci-check || warning "bin/ci-check a signalé des points à vérifier"
    echo
fi

# ============================================================
# 9. README DU PROJET
# ============================================================

step "9/11 — Remplacement du README du projet"

cp "$TEMPLATE_README" README.md

info "Remplacement des variables dans le README..."

sed "${SED_INPLACE[@]}" \
    -e "s#{{SITE_TITLE}}#${SITE_TITLE}#g" \
    -e "s#{{PROJECT_SLUG}}#${PROJECT_SLUG}#g" \
    -e "s#{{DDEV_DOMAIN}}#${DDEV_DOMAIN}#g" \
    -e "s#{{ADMIN_USER}}#${ADMIN_USER}#g" \
    -e "s#{{ADMIN_EMAIL}}#${ADMIN_EMAIL}#g" \
    README.md

success "README du projet remplacé par le template Tealforge"
success "Variables du README injectées (SITE_TITLE, PROJECT_SLUG, DDEV_DOMAIN, ADMIN_USER, ADMIN_EMAIL)"

# ============================================================
# 10. INITIALISATION GIT
# ============================================================

step "10/11 — Initialisation du dépôt Git"

info "Identité Git : $GIT_USER_NAME <$GIT_USER_EMAIL> (déjà vérifiée à l'étape 1/11)"

echo

info "Réinitialisation de l'historique Git..."

# Le dossier vient d'être cloné depuis le boilerplate : on repart d'un
# historique propre pour n'avoir qu'un unique commit initial de projet.
if [ -d ".git" ]; then
    rm -rf .git
fi

git init -b main >/dev/null

success "Dépôt Git initialisé sur la branche main"

echo

info "Vérification des fichiers sensibles..."

# Le core WordPress ne doit jamais être suivi par Git.
if ! git check-ignore -q "${WP_PATH}/wp-config.php" 2>/dev/null; then
    warning "wp-config.php n'est pas ignoré : ajout à .gitignore"
    printf '\n%s\n' "${WP_PATH}/wp-config.php" >> .gitignore
fi

success "wp-config.php ignoré"

# Le fichier de déploiement local contient des secrets.
if [ -f "deploy.local.env" ] && ! git check-ignore -q "deploy.local.env" 2>/dev/null; then
    warning "deploy.local.env n'est pas ignoré : ajout à .gitignore"
    printf '\ndeploy.local.env\n' >> .gitignore
fi

success "deploy.local.env ignoré"

echo

info "Ajout des fichiers au dépôt..."

git add .

# Double sécurité avant le commit.
if git ls-files --error-unmatch "${WP_PATH}/wp-config.php" >/dev/null 2>&1; then
    error "wp-config.php est suivi par Git. Commit annulé pour éviter d'exposer des secrets."
fi

if [ -f "deploy.local.env" ] && git ls-files --error-unmatch "deploy.local.env" >/dev/null 2>&1; then
    error "deploy.local.env est suivi par Git. Commit annulé."
fi

success "Fichiers préparés pour le commit"

echo

info "Création du commit initial..."

git commit -m "$GIT_INITIAL_COMMIT" >/dev/null

success "Commit créé : $GIT_INITIAL_COMMIT"

echo

info "Vérification des remotes Git..."

if [ -n "$(git remote)" ]; then
    error "Un remote Git est déjà configuré alors que le dépôt doit rester local."
fi

success "Aucun remote configuré"
success "Projet prêt à être lié à un dépôt distant (git remote add origin ...)"

# ============================================================
# RÉSUMÉ
# ============================================================

title "INSTALLATION TERMINÉE"

echo -e "  Projet           : ${BOLD}$PROJECT_NAME${RESET}"
echo -e "  Dossier          : ${BOLD}$(pwd)${RESET}"
echo -e "  Thème            : ${BOLD}tealforge${RESET}"
echo -e "  Stack            : ${BOLD}WordPress + Timber/Twig${RESET}"
echo -e "  Git              : ${BOLD}main — dépôt local${RESET}"

echo

separator

echo

echo -e "  Site             : ${GREEN}https://$DDEV_DOMAIN${RESET}"
echo -e "  Administration   : ${GREEN}https://$DDEV_DOMAIN/wp-admin${RESET}"

echo

separator

echo

echo -e "  Utilisateur admin: ${GREEN}${ADMIN_USER}${RESET}"
echo -e "  Email admin      : ${GREEN}${ADMIN_EMAIL}${RESET}"
echo -e "  Mot de passe     : ${GREEN}${ADMIN_PASSWORD}${RESET}"

echo

separator

echo

echo -e "  Commit initial   : ${BOLD}$GIT_INITIAL_COMMIT${RESET}"
echo -e "  Remote Git       : ${BOLD}aucun${RESET}"

echo

separator

echo

echo -e "  Pour lier le dépôt distant :"
echo -e "  ${DIM}git remote add origin git@github.com:ORGANISATION/${PROJECT_SLUG}.git${RESET}"
echo -e "  ${DIM}git push -u origin main${RESET}"

# ============================================================
# OUVERTURE
# ============================================================

step "11/11 — Ouverture du site"

info "Ouverture du site via DDEV..."

ddev launch

success "Application ouverte"