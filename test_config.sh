# Configuration pour les tests GitKtti
# Ce fichier peut être sourcé pour définir des variables d'environnement de test

# Répertoire racine du projet
export GITKTTI_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Répertoire des tests
export GITKTTI_TEST_DIR="$GITKTTI_ROOT/t"

# Configuration Perl
export PERL5LIB="$GITKTTI_ROOT/modules:$PERL5LIB"

# Configuration des tests
export TEST_VERBOSE=0
export TEST_COVERAGE=0

# Couleurs pour la sortie
export COLOR_RED='\033[0;31m'
export COLOR_GREEN='\033[0;32m'
export COLOR_YELLOW='\033[1;33m'
export COLOR_BLUE='\033[0;34m'
export COLOR_NC='\033[0m' # No Color

# Fonction pour afficher des messages colorés
gitktti_log() {
    local level=$1
    shift
    case $level in
        ERROR)   echo -e "${COLOR_RED}[ERROR]${COLOR_NC} $*" ;;
        SUCCESS) echo -e "${COLOR_GREEN}[SUCCESS]${COLOR_NC} $*" ;;
        WARNING) echo -e "${COLOR_YELLOW}[WARNING]${COLOR_NC} $*" ;;
        INFO)    echo -e "${COLOR_BLUE}[INFO]${COLOR_NC} $*" ;;
        *)       echo "$*" ;;
    esac
}

# Fonction pour exécuter les tests
gitktti_run_tests() {
    local args="$*"

    gitktti_log INFO "Démarrage des tests GitKtti..."

    cd "$GITKTTI_ROOT"

    if [ ! -x "./run_tests.pl" ]; then
        gitktti_log ERROR "Script de test non trouvé ou non exécutable"
        return 1
    fi

    if ./run_tests.pl $args; then
        gitktti_log SUCCESS "Tous les tests sont passés !"
        return 0
    else
        gitktti_log ERROR "Certains tests ont échoué"
        return 1
    fi
}

# Fonction pour vérifier la syntaxe
gitktti_check_syntax() {
    gitktti_log INFO "Vérification de la syntaxe..."

    cd "$GITKTTI_ROOT"
    local error=0

    for script in *.pl modules/*.pm; do
        if [ -f "$script" ]; then
            gitktti_log INFO "Vérification de $script..."
            if ! perl -c "$script" >/dev/null 2>&1; then
                gitktti_log ERROR "Erreur de syntaxe dans $script"
                error=1
            fi
        fi
    done

    if [ $error -eq 0 ]; then
        gitktti_log SUCCESS "Toutes les vérifications de syntaxe sont OK"
        return 0
    else
        gitktti_log ERROR "Des erreurs de syntaxe ont été trouvées"
        return 1
    fi
}

# Fonction pour installer les dépendances
gitktti_install_deps() {
    gitktti_log INFO "Installation des dépendances de test..."

    local modules=(
        "Test::More"
        "Time::HiRes"
        "File::Temp"
        "Getopt::Long"
        "FindBin"
    )

    for module in "${modules[@]}"; do
        gitktti_log INFO "Vérification du module $module..."
        if ! perl -M"$module" -e 1 2>/dev/null; then
            gitktti_log WARNING "Installation de $module..."
            cpan "$module"
        else
            gitktti_log SUCCESS "$module est déjà installé"
        fi
    done
}

# Afficher la configuration
gitktti_show_config() {
    echo "Configuration GitKtti Tests:"
    echo "  Racine du projet: $GITKTTI_ROOT"
    echo "  Répertoire tests: $GITKTTI_TEST_DIR"
    echo "  PERL5LIB: $PERL5LIB"
    echo ""
}

# Si ce script est sourcé, afficher la configuration
if [ "${BASH_SOURCE[0]}" != "${0}" ]; then
    gitktti_show_config
    gitktti_log SUCCESS "Configuration chargée. Fonctions disponibles:"
    echo "  - gitktti_run_tests [options]"
    echo "  - gitktti_check_syntax"
    echo "  - gitktti_install_deps"
    echo "  - gitktti_show_config"
fi
