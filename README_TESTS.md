# Tests Unitaires GitKtti - Guide Rapide

## 🚀 Démarrage Rapide

### Installation et Configuration

```bash
# Clone du projet
git clone <repository-url>
cd gitktti

# Installation automatique
./setup_tests.sh

# Ou installation avec hook Git
./setup_tests.sh --with-hook
```

### Exécution des Tests

```bash
# Tests complets
make test

# Tests détaillés
make test-verbose

# Tests avec couverture
make test-coverage

# Validation complète
make validate
```

## 📋 Structure des Tests

```text
t/
├── 01-utils.t              # Tests utilitaires de base
├── 02-git-integration.t    # Tests d'intégration Git
├── 03-scripts-validation.t # Validation des scripts
├── 04-performance-robustness.t # Performance et robustesse
└── 05-coverage.t           # Couverture complète
```

## ⚡ Commandes Essentielles

```bash
# Test rapide d'un seul fichier
perl t/01-utils.t

# Vérification syntaxique complète
make syntax-check

# Pipeline CI complet
./ci.sh

# Nettoyage
make clean
```

## 📊 Indicateurs de Qualité

- ✅ **Syntaxe** - Tous les scripts passent `perl -c`
- ✅ **Tests** - Plus de 50 tests unitaires
- ✅ **Couverture** - Toutes les fonctions testées
- ✅ **Performance** - Tests de performance inclus
- ✅ **Robustesse** - Tests de cas limites

## 🔧 Dépendances

**Modules Perl requis:**

- Test::More (tests)
- Time::HiRes (performance)
- File::Temp (fichiers temporaires)
- Getopt::Long (arguments)
- FindBin (chemins)

**Optionnels:**

- Devel::Cover (couverture)
- Perl::Critic (analyse statique)

## 🎯 Tests par Catégorie

### Tests Unitaires (`01-utils.t`)

- Fonctions de formatage (LPad, RPad, trim)
- Fonction launch pour commandes shell
- Gestion des répertoires
- Affichage de version

### Tests Git (`02-git-integration.t`)

- Détection repository Git
- Branches locales/distantes
- Statut du repository
- Opérations fetch/tag

### Validation Scripts (`03-scripts-validation.t`)

- Existence des fichiers
- Permissions d'exécution
- Syntaxe Perl valide

### Performance (`04-performance-robustness.t`)

- Temps d'exécution des fonctions
- Gestion d'entrées invalides
- Tests de cas limites

### Couverture (`05-coverage.t`)

- Existence de toutes les fonctions
- Tests de cohérence
- Gestion des erreurs

## 🔄 Intégration Continue

### GitHub Actions

Le workflow `.github/workflows/tests.yml` exécute :

- Tests sur multiple versions Perl (5.30, 5.32, 5.34)
- Génération de rapport de couverture
- Analyse statique du code

### Hook Git Pre-commit

```bash
# Installation automatique
./setup_tests.sh --with-hook
```

## 🛠️ Développement

### Ajouter un Test

```perl
# Nouveau fichier t/06-mon-test.t
#!/usr/bin/perl
use strict;
use warnings;
use Test::More tests => 3;
use FindBin qw($Bin);
use lib "$Bin/../modules";

BEGIN {
    use_ok('GitKttiUtils') || print "Bail out!\n";
}

subtest 'Mon nouveau test' => sub {
    plan tests => 2;

    ok(1, 'Test qui réussit');
    is(2+2, 4, 'Test mathématique');
};

done_testing();
```

### Débugger un Test

```bash
# Mode debug Perl
perl -d t/01-utils.t

# Sortie détaillée
./run_tests.pl --verbose

# Test isolé avec traces
perl -MCarp=verbose t/01-utils.t
```

## 📈 Métriques

Le fichier `test-metrics.json` contient :

- Nombre de lignes de code
- Nombre de fichiers de test
- Version Perl utilisée
- Informations Git (commit, branche)

## 🚨 Dépannage

### Problèmes Courants

#### "Module not found"

```bash
export PERL5LIB="$(pwd)/modules:$PERL5LIB"
```

#### "Permission denied"

```bash
chmod +x t/*.t *.pl
```

#### Tests Git échouent

- Vérifiez d'être dans un repository Git
- Certains tests nécessitent une branche trackée

### Support

- 📖 Documentation complète : `TESTING.md`
- 🔍 Configuration : `test_config.sh`
- ⚙️ Makefile : `make help`

---

**🎉 Happy Testing!**

Pour plus de détails, consultez `TESTING.md`
