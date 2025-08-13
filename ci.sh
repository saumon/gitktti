#!/bin/bash
##############################################################################
## Script d'intégration continue pour GitKtti
## Compatible avec GitHub Actions, GitLab CI, Jenkins, etc.
## by ROBU
##############################################################################

set -e

# Variables d'environnement
CI_MODE="${CI_MODE:-local}"
COVERAGE_REPORT="${COVERAGE_REPORT:-false}"
LINT_CHECK="${LINT_CHECK:-false}"
VERBOSE_OUTPUT="${VERBOSE_OUTPUT:-false}"

# Couleurs (désactivées en mode CI)
if [ "$CI_MODE" = "local" ]; then
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[1;33m'
    BLUE='\033[0;34m'
    NC='\033[0m'
else
    RED=''
    GREEN=''
    YELLOW=''
    BLUE=''
    NC=''
fi

# Fonctions de logging
log_info() {
    echo -e "${BLUE}[CI-INFO]${NC} $*"
}

log_success() {
    echo -e "${GREEN}[CI-SUCCESS]${NC} $*"
}

log_warning() {
    echo -e "${YELLOW}[CI-WARNING]${NC} $*"
}

log_error() {
    echo -e "${RED}[CI-ERROR]${NC} $*"
}

log_step() {
    echo ""
    echo "=================================================================================="
    echo "ÉTAPE: $*"
    echo "=================================================================================="
}

# Vérification de l'environnement
check_environment() {
    log_step "Vérification de l'environnement"

    # Perl
    if ! command -v perl >/dev/null 2>&1; then
        log_error "Perl non trouvé"
        exit 1
    fi
    log_info "Perl: $(perl -v | grep -o 'v[0-9.]*' | head -1)"

    # Git
    if command -v git >/dev/null 2>&1; then
        log_info "Git: $(git --version)"
        if git rev-parse --git-dir >/dev/null 2>&1; then
            log_info "Repository Git détecté"
            log_info "Branche: $(git rev-parse --abbrev-ref HEAD)"
            log_info "Commit: $(git rev-parse --short HEAD)"
        fi
    else
        log_warning "Git non disponible"
    fi

    # Make
    if command -v make >/dev/null 2>&1; then
        log_info "Make disponible"
    else
        log_warning "Make non disponible - utilisation de scripts directs"
    fi

    log_success "Environnement vérifié"
}

# Installation des dépendances
install_dependencies() {
    log_step "Installation des dépendances"

    local modules=(
        "Test::More"
        "Time::HiRes"
        "File::Temp"
        "Getopt::Long"
        "FindBin"
    )

    if [ "$COVERAGE_REPORT" = "true" ]; then
        modules+=("Devel::Cover")
    fi

    if [ "$LINT_CHECK" = "true" ]; then
        modules+=("Perl::Critic")
    fi

    log_info "Vérification des modules Perl..."
    local missing=()

    for module in "${modules[@]}"; do
        if perl -M"$module" -e 1 2>/dev/null; then
            log_info "✓ $module"
        else
            log_warning "✗ $module (manquant)"
            missing+=("$module")
        fi
    done

    if [ ${#missing[@]} -gt 0 ]; then
        log_info "Installation des modules manquants..."

        # En mode CI, utiliser cpanm si disponible
        if command -v cpanm >/dev/null 2>&1; then
            cpanm --quiet --notest "${missing[@]}"
        elif command -v cpan >/dev/null 2>&1; then
            for module in "${missing[@]}"; do
                echo "yes" | cpan "$module"
            done
        else
            log_error "Aucun installateur de modules trouvé (cpan/cpanm)"
            exit 1
        fi

        log_success "Modules installés"
    else
        log_success "Toutes les dépendances sont disponibles"
    fi
}

# Vérification syntaxique
syntax_check() {
    log_step "Vérification syntaxique"

    local error_count=0
    local files=(
        *.pl
        modules/*.pm
    )

    for pattern in "${files[@]}"; do
        for file in $pattern; do
            if [ -f "$file" ]; then
                log_info "Vérification de $file..."
                if perl -c "$file" >/dev/null 2>&1; then
                    log_info "✓ $file"
                else
                    log_error "✗ $file - Erreur de syntaxe"
                    perl -c "$file"
                    ((error_count++))
                fi
            fi
        done
    done

    if [ $error_count -gt 0 ]; then
        log_error "$error_count erreur(s) de syntaxe trouvée(s)"
        exit 1
    fi

    log_success "Vérification syntaxique réussie"
}

# Exécution des tests
run_tests() {
    log_step "Exécution des tests"

    local test_args=""
    if [ "$VERBOSE_OUTPUT" = "true" ]; then
        test_args="--verbose"
    fi

    if [ "$COVERAGE_REPORT" = "true" ]; then
        test_args="$test_args --coverage"
    fi

    # Utiliser notre script de test personnalisé
    if [ -x "./run_tests.pl" ]; then
        log_info "Exécution avec run_tests.pl $test_args"
        ./run_tests.pl $test_args
    # Ou make si disponible
    elif command -v make >/dev/null 2>&1 && [ -f "Makefile" ]; then
        if [ "$VERBOSE_OUTPUT" = "true" ]; then
            make test-verbose
        elif [ "$COVERAGE_REPORT" = "true" ]; then
            make test-coverage
        else
            make test
        fi
    # Ou exécution directe
    else
        log_info "Exécution directe des tests..."
        for test_file in t/*.t; do
            if [ -f "$test_file" ]; then
                log_info "Exécution de $(basename "$test_file")..."
                perl "$test_file"
            fi
        done
    fi

    log_success "Tests exécutés avec succès"
}

# Analyse statique (linting)
run_lint() {
    if [ "$LINT_CHECK" != "true" ]; then
        return
    fi

    log_step "Analyse statique (linting)"

    if ! command -v perlcritic >/dev/null 2>&1; then
        log_warning "perlcritic non disponible - analyse ignorée"
        return
    fi

    local files=(*.pl modules/*.pm)
    local warning_count=0

    for pattern in "${files[@]}"; do
        for file in $pattern; do
            if [ -f "$file" ]; then
                log_info "Analyse de $file..."
                local output
                output=$(perlcritic --severity 3 --quiet "$file" 2>&1 || true)
                if [ -n "$output" ]; then
                    log_warning "Avertissements dans $file:"
                    echo "$output"
                    ((warning_count++))
                fi
            fi
        done
    done

    if [ $warning_count -gt 0 ]; then
        log_warning "$warning_count fichier(s) avec des avertissements"
    else
        log_success "Aucun problème de style trouvé"
    fi
}

# Génération du rapport de couverture
generate_coverage_report() {
    if [ "$COVERAGE_REPORT" != "true" ]; then
        return
    fi

    log_step "Génération du rapport de couverture"

    if command -v cover >/dev/null 2>&1; then
        # Générer le rapport HTML
        cover -report html_minimal

        # En mode CI, afficher un résumé
        if [ "$CI_MODE" != "local" ]; then
            cover -report text
        fi

        log_success "Rapport de couverture généré"
    else
        log_warning "cover non disponible - rapport ignoré"
    fi
}

# Collecte des métriques
collect_metrics() {
    log_step "Collecte des métriques"

    local metrics_file="test-metrics.json"

    # Compter les lignes de code
    local lines_of_code=0
    for file in *.pl modules/*.pm; do
        if [ -f "$file" ]; then
            lines_of_code=$((lines_of_code + $(wc -l < "$file")))
        fi
    done

    # Compter les tests
    local test_count=0
    for file in t/*.t; do
        if [ -f "$file" ]; then
            test_count=$((test_count + 1))
        fi
    done

    # Créer le fichier de métriques
    cat > "$metrics_file" << EOF
{
    "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
    "lines_of_code": $lines_of_code,
    "test_files": $test_count,
    "perl_version": "$(perl -v | grep -o 'v[0-9.]*' | head -1)",
    "git_commit": "$(git rev-parse HEAD 2>/dev/null || echo 'N/A')",
    "git_branch": "$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo 'N/A')"
}
EOF

    log_info "Métriques sauvegardées dans $metrics_file"
    log_success "Métriques collectées"
}

# Nettoyage
cleanup() {
    log_step "Nettoyage"

    # Nettoyer les fichiers temporaires
    find . -name "*.tmp" -delete 2>/dev/null || true
    find . -name "*~" -delete 2>/dev/null || true

    # Garder les rapports de couverture en mode CI
    if [ "$CI_MODE" = "local" ] && [ "$COVERAGE_REPORT" != "true" ]; then
        rm -rf cover_db/ 2>/dev/null || true
    fi

    log_success "Nettoyage terminé"
}

# Affichage de l'aide
show_help() {
    echo "Usage: $0 [options]"
    echo ""
    echo "Variables d'environnement:"
    echo "  CI_MODE=local|ci       Mode d'exécution (défaut: local)"
    echo "  COVERAGE_REPORT=true   Générer un rapport de couverture"
    echo "  LINT_CHECK=true        Exécuter l'analyse statique"
    echo "  VERBOSE_OUTPUT=true    Sortie détaillée"
    echo ""
    echo "Exemples:"
    echo "  $0                           # Exécution basique"
    echo "  COVERAGE_REPORT=true $0      # Avec couverture"
    echo "  LINT_CHECK=true $0           # Avec linting"
    echo "  CI_MODE=ci $0                # Mode CI"
    echo ""
}

# Gestionnaire de signaux
trap cleanup EXIT

# Point d'entrée principal
main() {
    case "${1:-}" in
        --help|-h)
            show_help
            exit 0
            ;;
    esac

    log_info "Démarrage du pipeline CI GitKtti"
    log_info "Mode: $CI_MODE"

    check_environment
    install_dependencies
    syntax_check
    run_tests
    run_lint
    generate_coverage_report
    collect_metrics

    log_success "Pipeline CI terminé avec succès !"
}

# Exécution
main "$@"
