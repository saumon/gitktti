#!/bin/bash
##############################################################################
## Script d'installation et configuration des tests GitKtti
## by ROBU
##############################################################################

set -e  # Arrêt en cas d'erreur

# Couleurs pour la sortie
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Fonctions utilitaires
log_info() {
    echo -e "${BLUE}[INFO]${NC} $*"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $*"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $*"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $*"
}

# Vérifier que nous sommes dans le bon répertoire
check_directory() {
    if [ ! -f "modules/GitKttiUtils.pm" ]; then
        log_error "Ce script doit être exécuté depuis la racine du projet GitKtti"
        exit 1
    fi
    log_success "Répertoire du projet détecté"
}

# Vérifier Perl
check_perl() {
    log_info "Vérification de Perl..."

    if ! command -v perl >/dev/null 2>&1; then
        log_error "Perl n'est pas installé"
        exit 1
    fi

    local perl_version=$(perl -v | grep -o 'v[0-9.]*' | head -1)
    log_success "Perl $perl_version détecté"
}

# Installer les modules Perl requis
install_perl_modules() {
    log_info "Installation des modules Perl requis..."

    local modules=(
        "Test::More"
        "Time::HiRes"
        "File::Temp"
        "Getopt::Long"
        "FindBin"
    )

    local missing_modules=()

    # Vérifier quels modules manquent
    for module in "${modules[@]}"; do
        if ! perl -M"$module" -e 1 2>/dev/null; then
            missing_modules+=("$module")
        else
            log_success "$module est déjà installé"
        fi
    done

    # Installer les modules manquants
    if [ ${#missing_modules[@]} -gt 0 ]; then
        log_info "Installation des modules manquants: ${missing_modules[*]}"

        # Essayer avec cpan
        if command -v cpan >/dev/null 2>&1; then
            for module in "${missing_modules[@]}"; do
                log_info "Installation de $module avec cpan..."
                cpan "$module"
            done
        # Essayer avec cpanm si disponible
        elif command -v cpanm >/dev/null 2>&1; then
            log_info "Installation avec cpanm..."
            cpanm "${missing_modules[@]}"
        else
            log_warning "cpan/cpanm non trouvé. Installation manuelle nécessaire:"
            for module in "${missing_modules[@]}"; do
                echo "  cpan $module"
            done
            return 1
        fi
    else
        log_success "Tous les modules Perl requis sont installés"
    fi
}

# Configurer les permissions
setup_permissions() {
    log_info "Configuration des permissions..."

    # Scripts principaux
    chmod +x *.pl 2>/dev/null || true

    # Scripts de test
    chmod +x t/*.t 2>/dev/null || true
    chmod +x run_tests.pl 2>/dev/null || true
    chmod +x test_config.sh 2>/dev/null || true

    log_success "Permissions configurées"
}

# Vérifier Git
check_git() {
    log_info "Vérification de Git..."

    if ! command -v git >/dev/null 2>&1; then
        log_warning "Git n'est pas installé - certains tests seront ignorés"
        return
    fi

    if ! git rev-parse --git-dir >/dev/null 2>&1; then
        log_warning "Pas dans un repository Git - certains tests seront ignorés"
        return
    fi

    log_success "Repository Git détecté"
}

# Exécuter les tests de base
run_basic_tests() {
    log_info "Exécution des tests de base..."

    # Test de syntaxe
    if make syntax-check >/dev/null 2>&1; then
        log_success "Vérification syntaxique OK"
    else
        log_error "Erreurs de syntaxe détectées"
        return 1
    fi

    # Test basique
    if perl t/01-utils.t >/dev/null 2>&1; then
        log_success "Tests utilitaires OK"
    else
        log_error "Échec des tests utilitaires"
        return 1
    fi

    log_success "Tests de base réussis"
}

# Installer un hook Git pre-commit (optionnel)
install_git_hook() {
    if [ "$1" != "--with-hook" ]; then
        return
    fi

    log_info "Installation du hook Git pre-commit..."

    local hook_file=".git/hooks/pre-commit"

    if [ ! -d ".git/hooks" ]; then
        log_warning "Répertoire .git/hooks non trouvé"
        return
    fi

    cat > "$hook_file" << 'EOF'
#!/bin/bash
# GitKtti pre-commit hook
# Exécute les tests avant chaque commit

echo "Exécution des tests GitKtti..."
cd "$(git rev-parse --show-toplevel)"

if make syntax-check >/dev/null 2>&1; then
    echo "✓ Syntaxe OK"
else
    echo "✗ Erreurs de syntaxe détectées"
    exit 1
fi

if perl t/01-utils.t >/dev/null 2>&1; then
    echo "✓ Tests utilitaires OK"
else
    echo "✗ Tests utilitaires échoués"
    exit 1
fi

echo "✓ Tous les tests sont passés"
EOF

    chmod +x "$hook_file"
    log_success "Hook pre-commit installé"
}

# Créer un fichier de configuration local
create_config() {
    log_info "Création du fichier de configuration..."

    cat > ".gitktti_test_config" << EOF
# Configuration des tests GitKtti
# Généré le $(date)

# Répertoire racine
GITKTTI_ROOT=$(pwd)

# Version Perl
PERL_VERSION=$(perl -v | grep -o 'v[0-9.]*' | head -1)

# Modules installés
MODULES_CHECKED=$(date +%Y%m%d_%H%M%S)

# Repository Git
GIT_REPOSITORY=$(git rev-parse --show-toplevel 2>/dev/null || echo "N/A")
GIT_BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "N/A")
EOF

    log_success "Configuration sauvegardée dans .gitktti_test_config"
}

# Afficher un résumé
show_summary() {
    echo ""
    echo "=================================================================================="
    echo "GitKtti Tests - Installation Terminée"
    echo "=================================================================================="
    echo ""
    echo "Commandes disponibles:"
    echo "  make test           - Exécuter tous les tests"
    echo "  make test-verbose   - Tests avec sortie détaillée"
    echo "  make syntax-check   - Vérification syntaxique"
    echo "  ./run_tests.pl      - Script de test personnalisé"
    echo ""
    echo "Fichiers utiles:"
    echo "  TESTING.md          - Documentation des tests"
    echo "  Makefile            - Commandes automatisées"
    echo "  test_config.sh      - Configuration shell"
    echo ""
    echo "Pour plus d'informations, consultez TESTING.md"
    echo ""
}

# Fonction principale
main() {
    echo "=================================================================================="
    echo "GitKtti Tests - Script d'Installation"
    echo "=================================================================================="
    echo ""

    check_directory
    check_perl
    check_git
    setup_permissions

    # Installation des modules avec confirmation
    if install_perl_modules; then
        log_success "Modules Perl installés"
    else
        log_warning "Certains modules Perl peuvent manquer"
    fi

    create_config

    # Tests de base
    if run_basic_tests; then
        log_success "Installation vérifiée"
    else
        log_error "Problèmes détectés lors de l'installation"
        exit 1
    fi

    # Hook Git optionnel
    install_git_hook "$1"

    show_summary

    log_success "Installation terminée avec succès !"
}

# Afficher l'aide
show_help() {
    echo "Usage: $0 [options]"
    echo ""
    echo "Options:"
    echo "  --with-hook    Installer un hook Git pre-commit"
    echo "  --help         Afficher cette aide"
    echo ""
    echo "Ce script configure l'environnement de test pour GitKtti:"
    echo "  - Vérifie les dépendances"
    echo "  - Installe les modules Perl requis"
    echo "  - Configure les permissions"
    echo "  - Exécute des tests de validation"
    echo ""
}

# Point d'entrée
case "${1:-}" in
    --help|-h)
        show_help
        ;;
    *)
        main "$@"
        ;;
esac
