#!/bin/bash
##############################################################################
## Vérification rapide de l'installation des tests GitKtti
## by ROBU
##############################################################################

echo "🔍 Vérification rapide de l'installation des tests GitKtti"
echo "============================================================="

# Compteurs
success_count=0
total_count=0

# Fonction de test
check_item() {
    local description="$1"
    local command="$2"
    local expected_exit_code="${3:-0}"

    ((total_count++))
    printf "%-50s" "$description"

    if eval "$command" >/dev/null 2>&1; then
        local exit_code=$?
        if [ $exit_code -eq $expected_exit_code ]; then
            echo "✅"
            ((success_count++))
        else
            echo "❌ (code: $exit_code)"
        fi
    else
        echo "❌"
    fi
}

echo ""
echo "📁 Structure des fichiers"
echo "-------------------------"
check_item "Module GitKttiUtils.pm" "[ -f modules/GitKttiUtils.pm ]"
check_item "Tests unitaires (5 fichiers)" "[ $(ls t/*.t 2>/dev/null | wc -l) -eq 5 ]"
check_item "Script run_tests.pl" "[ -x run_tests.pl ]"
check_item "Script setup_tests.sh" "[ -x setup_tests.sh ]"
check_item "Makefile" "[ -f Makefile ]"
check_item "Documentation TESTING.md" "[ -f TESTING.md ]"

echo ""
echo "⚙️ Environnement Perl"
echo "---------------------"
check_item "Perl disponible" "command -v perl"
check_item "Module Test::More" "perl -MTest::More -e 1"
check_item "Module Time::HiRes" "perl -MTime::HiRes -e 1"
check_item "Module File::Temp" "perl -MFile::Temp -e 1"
check_item "Module FindBin" "perl -MFindBin -e 1"

echo ""
echo "🔧 Syntaxe des scripts"
echo "----------------------"
check_item "GitKttiUtils.pm syntaxe" "perl -c modules/GitKttiUtils.pm"
check_item "run_tests.pl syntaxe" "perl -c run_tests.pl"
check_item "Tests 01-utils.t syntaxe" "perl -c t/01-utils.t"
check_item "Tests 02-git-integration.t syntaxe" "perl -c t/02-git-integration.t"
check_item "Tests 03-scripts-validation.t syntaxe" "perl -c t/03-scripts-validation.t"

echo ""
echo "🧪 Tests fonctionnels"
echo "---------------------"
check_item "Test unitaire basique" "perl t/01-utils.t"
check_item "Validation des scripts" "perl t/03-scripts-validation.t"
check_item "Test de performance" "perl t/04-performance-robustness.t"

echo ""
echo "🚀 Commandes disponibles"
echo "------------------------"
check_item "make test" "make -n test"
check_item "make syntax-check" "make -n syntax-check"
check_item "make help" "make -n help"

if command -v git >/dev/null 2>&1 && git rev-parse --git-dir >/dev/null 2>&1; then
    echo ""
    echo "📂 Environnement Git"
    echo "--------------------"
    check_item "Repository Git détecté" "git rev-parse --git-dir"
    check_item "Tests Git fonctionnels" "perl t/02-git-integration.t"
fi

echo ""
echo "📊 RÉSUMÉ"
echo "========="
echo "Tests réussis : $success_count/$total_count"

if [ $success_count -eq $total_count ]; then
    echo "🎉 Toutes les vérifications sont OK !"
    echo ""
    echo "✅ L'installation des tests est complète et fonctionnelle"
    echo ""
    echo "🚀 Commandes recommandées :"
    echo "   make test           # Lancer tous les tests"
    echo "   make test-verbose   # Tests avec détails"
    echo "   make validate       # Validation complète"
    echo ""
    echo "📖 Documentation :"
    echo "   cat TESTING.md      # Guide complet"
    echo "   cat README_TESTS.md # Guide rapide"

    exit 0
else
    echo "⚠️  Certaines vérifications ont échoué ($((total_count - success_count))/$total_count)"
    echo ""
    echo "🔧 Actions recommandées :"

    if ! command -v perl >/dev/null 2>&1; then
        echo "   - Installer Perl"
    fi

    if ! perl -MTest::More -e 1 2>/dev/null; then
        echo "   - Installer les modules Perl : ./setup_tests.sh"
    fi

    echo "   - Vérifier les permissions : chmod +x *.pl t/*.t"
    echo "   - Consulter TESTING.md pour plus d'aide"

    exit 1
fi
