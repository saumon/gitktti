# Makefile pour GitKtti
# by ROBU

.PHONY: test test-verbose test-coverage clean install help

# Variables
PERL = perl
TEST_RUNNER = ./run_tests.pl
TEST_DIR = t

# Cible par défaut
all: test

# Exécuter tous les tests
test:
	@echo "Exécution des tests GitKtti..."
	@$(TEST_RUNNER)

# Exécuter les tests en mode verbose
test-verbose:
	@echo "Exécution des tests GitKtti (mode verbose)..."
	@$(TEST_RUNNER) --verbose

# Exécuter les tests avec analyse de couverture
test-coverage:
	@echo "Exécution des tests GitKtti avec analyse de couverture..."
	@$(TEST_RUNNER) --coverage

# Exécuter un test spécifique
test-single:
	@if [ -z "$(FILE)" ]; then \
		echo "Usage: make test-single FILE=nom_du_fichier.t"; \
		exit 1; \
	fi
	@echo "Exécution du test $(FILE)..."
	@$(PERL) $(TEST_DIR)/$(FILE)

# Vérifier la syntaxe de tous les scripts
syntax-check:
	@echo "Vérification de la syntaxe des scripts..."
	@for script in *.pl modules/*.pm; do \
		echo "Vérification de $$script..."; \
		$(PERL) -c "$$script" || exit 1; \
	done
	@echo "Toutes les vérifications de syntaxe sont OK !"

# Installer les dépendances de test
install-deps:
	@echo "Installation des dépendances de test..."
	@cpan Test::More Time::HiRes File::Temp

# Nettoyer les fichiers temporaires
clean:
	@echo "Nettoyage des fichiers temporaires..."
	@rm -rf cover_db/
	@rm -f nytprof.out
	@find . -name "*.tmp" -delete
	@find . -name "*~" -delete

# Générer un rapport de couverture HTML
coverage-html: test-coverage
	@echo "Génération du rapport de couverture HTML..."
	@cover -report html

# Linter Perl (si disponible)
lint:
	@echo "Analyse statique du code..."
	@if command -v perlcritic >/dev/null 2>&1; then \
		perlcritic --severity 3 *.pl modules/*.pm; \
	else \
		echo "perlcritic non installé. Installez Perl::Critic pour l'analyse statique."; \
	fi

# Exécuter une suite complète de validation
validate: syntax-check test lint
	@echo "Validation complète terminée avec succès !"

# Afficher l'aide
help:
	@echo "Makefile pour GitKtti"
	@echo ""
	@echo "Cibles disponibles :"
	@echo "  test           - Exécuter tous les tests"
	@echo "  test-verbose   - Exécuter les tests en mode verbose"
	@echo "  test-coverage  - Exécuter les tests avec analyse de couverture"
	@echo "  test-single    - Exécuter un test spécifique (usage: make test-single FILE=test.t)"
	@echo "  syntax-check   - Vérifier la syntaxe de tous les scripts"
	@echo "  install-deps   - Installer les dépendances de test"
	@echo "  clean          - Nettoyer les fichiers temporaires"
	@echo "  coverage-html  - Générer un rapport de couverture HTML"
	@echo "  lint           - Analyse statique du code (nécessite perlcritic)"
	@echo "  validate       - Suite complète de validation"
	@echo "  help           - Afficher cette aide"
	@echo ""
	@echo "Exemples :"
	@echo "  make test"
	@echo "  make test-verbose"
	@echo "  make test-single FILE=01-utils.t"
	@echo "  make validate"
