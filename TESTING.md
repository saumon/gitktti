# Tests Unitaires GitKtti

Ce document explique comment utiliser et maintenir la suite de tests
unitaires pour le projet GitKtti.

## Structure des Tests

La suite de tests est organisée dans le répertoire `t/` avec les fichiers
suivants :

- `01-utils.t` - Tests des fonctions utilitaires de base
- `02-git-integration.t` - Tests d'intégration avec Git
- `03-scripts-validation.t` - Validation syntaxique des scripts
- `04-performance-robustness.t` - Tests de performance et robustesse
- `05-coverage.t` - Tests de couverture complète

## Exécution des Tests

### Méthode Simple

```bash
# Exécuter tous les tests
./run_tests.pl

# Exécuter avec sortie détaillée
./run_tests.pl --verbose

# Exécuter avec analyse de couverture
./run_tests.pl --coverage
```

### Avec Make

```bash
# Exécuter tous les tests
make test

# Tests avec sortie détaillée
make test-verbose

# Tests avec couverture
make test-coverage

# Validation complète (syntaxe + tests + lint)
make validate

# Test d'un fichier spécifique
make test-single FILE=01-utils.t
```

### Tests Individuels

```bash
# Exécuter un test spécifique
perl t/01-utils.t

# Vérifier la syntaxe seulement
perl -c t/01-utils.t
```

## Configuration de l'Environnement

### Dépendances Requises

- `Test::More` - Framework de test principal
- `Time::HiRes` - Pour les tests de performance
- `File::Temp` - Pour les fichiers temporaires
- `FindBin` - Pour localiser les modules

### Installation des Dépendances

```bash
# Installation manuelle
cpan Test::More Time::HiRes File::Temp

# Ou via le Makefile
make install-deps

# Ou via le script de configuration
source test_config.sh
gitktti_install_deps
```

## Description des Tests

### 01-utils.t - Tests Utilitaires

- Tests des fonctions de formatage (`LPad`, `RPad`, `trim`)
- Tests de la fonction `launch` pour l'exécution de commandes
- Tests de `directoryExists`
- Vérification de la version du module
- Tests structurels des fonctions

### 02-git-integration.t - Intégration Git

- Détection du repository Git
- Tests des fonctions Git (branches, statut, remotes)
- Tests des opérations fetch et tag
- **Note**: Nécessite d'être exécuté dans un repository Git

### 03-scripts-validation.t - Validation Scripts

- Vérification de l'existence des scripts
- Contrôle des permissions d'exécution
- Validation syntaxique Perl de tous les scripts

### 04-performance-robustness.t - Performance

- Tests de performance des fonctions de formatage
- Tests de robustesse avec entrées inattendues
- Tests de gestion d'erreurs
- Tests de cas limites

### 05-coverage.t - Couverture Complète

- Vérification de l'existence de toutes les fonctions
- Tests de cohérence des fonctions utilitaires
- Tests de gestion des états de retour
- Validation du module

## Intégration Continue

### Script d'Automatisation

Le fichier `test_config.sh` fournit des fonctions pour l'automatisation :

```bash
# Sourcer le fichier de configuration
source test_config.sh

# Fonctions disponibles
gitktti_run_tests [options]     # Exécuter les tests
gitktti_check_syntax           # Vérifier la syntaxe
gitktti_install_deps          # Installer les dépendances
gitktti_show_config           # Afficher la configuration
```

### Hooks Git (Recommandé)

Vous pouvez ajouter un hook pre-commit pour exécuter automatiquement les tests :

```bash
#!/bin/bash
# .git/hooks/pre-commit
cd "$(git rev-parse --show-toplevel)"
make test || exit 1
```

## Ajout de Nouveaux Tests

### Structure Recommandée

```perl
#!/usr/bin/perl
use strict;
use warnings;
use Test::More tests => N;  # Remplacer N par le nombre de tests
use FindBin qw($Bin);
use lib "$Bin/../modules";

BEGIN {
    use_ok('GitKttiUtils') || print "Bail out!\n";
}

subtest 'Description du test' => sub {
    plan tests => M;  # Remplacer M par le nombre de sous-tests

    # Vos tests ici
    ok(condition, 'Description du test');
    is(valeur_actuelle, valeur_attendue, 'Description');
};

done_testing();
```

### Bonnes Pratiques

1. **Isolation** - Chaque test doit être indépendant
2. **Descriptif** - Utilisez des descriptions claires
3. **Couverture** - Testez les cas normaux ET les cas d'erreur
4. **Performance** - Évitez les tests trop longs
5. **Reproductibilité** - Les tests doivent donner le même résultat

## Dépannage

### Problèmes Courants

#### "Module not found"

```bash
export PERL5LIB="$(pwd)/modules:$PERL5LIB"
```

#### "Permission denied"

```bash
chmod +x t/*.t run_tests.pl
```

#### Tests Git échouent

- Vérifiez que vous êtes dans un repository Git
- Certains tests nécessitent une branche trackée

#### Tests de performance échouent

- Les tests de performance peuvent varier selon la charge système
- Ajustez les seuils si nécessaire

### Debug

```bash
# Exécution avec debug Perl
perl -d t/01-utils.t

# Sortie détaillée
./run_tests.pl --verbose

# Test individuel avec sortie complète
perl t/01-utils.t 2>&1 | less
```

## Métriques et Rapports

### Couverture de Code

```bash
# Générer un rapport de couverture
make test-coverage
cover  # Voir le rapport HTML

# Ou directement
perl -MDevel::Cover t/01-utils.t
cover -report html
```

### Analyse Statique

```bash
# Installer perlcritic
cpan Perl::Critic

# Analyser le code
make lint
```

## Maintenance

### Mise à Jour des Tests

- Ajouter des tests pour chaque nouvelle fonction
- Mettre à jour les tests lors de changements d'API
- Maintenir la documentation à jour

### Nettoyage

```bash
# Nettoyer les fichiers temporaires
make clean
```

Ce système de tests assure la qualité et la fiabilité du code GitKtti lors des modifications.
