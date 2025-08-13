#!/usr/bin/perl
##############################################################################
## Tests de couverture complète pour toutes les fonctions GitKtti
## by ROBU
##############################################################################

use strict;
use warnings;
use Test::More;
use FindBin qw($Bin);
use lib "$Bin/../modules";

# Import du module
BEGIN {
    use_ok('GitKttiUtils') || print "Bail out!\n";
}

# Obtenir toutes les fonctions exportées par GitKttiUtils
my @all_functions = qw(
    showVersion
    launch
    isResponseYes
    getResponse
    getSelectResponse
    LPad
    RPad
    directoryExists
    git_getTrackedRemoteBranch
    git_getGitRootDirectory
    git_isRepoClean
    trim
    super_scp
    super_rsync_ssh
    super_rsync_ssh_with_exclude
    git_checkoutBranch
    git_checkoutBranchNoConfirm
    git_deleteLocalBranch
    git_getLocalBranchesFilter
    git_getRemoteBranchesFilter
    git_getAllBranchesFilter
    git_getCurrentBranch
    git_fetch
    git_getLastTagFromAllBranches
    git_getLastTagFromCurrentBranch
    git_cleanLocalTags
    git_fetchTags
    git_fetchPrune
    git_remotePrune
    git_getParentBranch
    git_tagBranch
    git_pullCurrentBranch
    git_deleteCurrentBranch
);

plan tests => 6;

# Test de l'existence de toutes les fonctions
subtest 'Function existence test' => sub {
    plan tests => scalar(@all_functions);

    for my $function (@all_functions) {
        can_ok('GitKttiUtils', $function);
    }
};

# Test des constantes
subtest 'Constants test' => sub {
    plan tests => 1;

    ok(defined GitKttiUtils::GIT_KTTI_VERSION, 'GIT_KTTI_VERSION constant exists');
};

# Test de cohérence des fonctions utilitaires
subtest 'Utility functions coherence' => sub {
    plan tests => 8;

    # Test de cohérence LPad/RPad
    my $test_str = "test";
    my $padded_left = GitKttiUtils::LPad($test_str, 10);
    my $padded_right = GitKttiUtils::RPad($test_str, 10);

    is(length($padded_left), 10, "LPad produces correct length");
    is(length($padded_right), 10, "RPad produces correct length");

    like($padded_left, qr/test$/, "LPad keeps original string at end");
    like($padded_right, qr/^test/, "RPad keeps original string at start");

    # Test de cohérence trim
    my $whitespace_str = "  \t  test  \t  ";
    my $trimmed = GitKttiUtils::trim($whitespace_str);

    is($trimmed, "test", "Trim removes all whitespace");
    is(GitKttiUtils::trim($trimmed), $trimmed, "Trim is idempotent");

    # Test de directoryExists avec répertoire connu
    ok(GitKttiUtils::directoryExists($Bin, ".."), "directoryExists finds parent directory");
    ok(!GitKttiUtils::directoryExists($Bin, "impossible_directory_name_xyz"), "directoryExists returns false for non-existent directory");
};

# Test de la gestion des états de retour
subtest 'Return state handling' => sub {
    plan tests => 4;

    my $state;

    # Test avec commande qui réussit
    GitKttiUtils::launch("echo success", \$state);
    is($state, 0, "Successful command sets state to 0");

    # Test avec commande qui échoue
    GitKttiUtils::launch("sh -c 'exit 1'", \$state);
    is($state, 1, "Failed command sets correct error state");

    # Test avec commande vide
    GitKttiUtils::launch("", \$state);
    is($state, 99, "Empty command sets state to 99");

    # Vérifier que l'état est bien passé par référence
    my $initial_state = 50;
    $state = $initial_state;
    GitKttiUtils::launch("true", \$state);
    isnt($state, $initial_state, "State is modified by reference");
};

# Test de validation du module
subtest 'Module validation' => sub {
    plan tests => 3;

    # Vérifier que le module peut être rechargé
    ok(eval { require GitKttiUtils; 1 }, "Module can be required");

    # Vérifier la structure du package
    ok(defined $GitKttiUtils::VERSION || defined &GitKttiUtils::GIT_KTTI_VERSION, "Module has version information");

    # Test de base de fonctionnement
    my $output;
    {
        local *STDOUT;
        open(STDOUT, '>', \$output) or die "Can't redirect STDOUT: $!";
        eval { GitKttiUtils::showVersion(); };
        close(STDOUT);
    }
    ok(!$@ && defined $output, "Basic module functionality works");
};

done_testing();
