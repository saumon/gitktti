#!/usr/bin/perl
##############################################################################
## Tests unitaires pour GitKttiUtils.pm
## by ROBU
##############################################################################

use strict;
use warnings;
use Test::More tests => 10;
use FindBin qw($Bin);
use lib "$Bin/../modules";

# Import du module à tester
BEGIN {
    use_ok('GitKttiUtils') || print "Bail out!\n";
}

# Test de la version
subtest 'Version tests' => sub {
    plan tests => 2;

    # Test que la constante de version existe
    ok(defined GitKttiUtils::GIT_KTTI_VERSION, 'Version constant is defined');

    # Test que la version a le bon format
    like(GitKttiUtils::GIT_KTTI_VERSION, qr/^\d+\.\d+\.\d+$/, 'Version format is correct');
};

# Test des fonctions utilitaires de formatage
subtest 'String formatting tests' => sub {
    plan tests => 6;

    # Tests pour LPad
    is(GitKttiUtils::LPad("test", 8), "    test", 'LPad with default space character');
    is(GitKttiUtils::LPad("test", 8, "0"), "0000test", 'LPad with custom character');
    is(GitKttiUtils::LPad("test", 3), "est", 'LPad truncates when string is longer');

    # Tests pour RPad
    is(GitKttiUtils::RPad("test", 8), "test    ", 'RPad with default space character');
    is(GitKttiUtils::RPad("test", 8, "0"), "test0000", 'RPad with custom character');
    is(GitKttiUtils::RPad("test", 3), "tes", 'RPad truncates when string is longer');
};

# Test de la fonction trim
subtest 'Trim function tests' => sub {
    plan tests => 4;

    is(GitKttiUtils::trim("  test  "), "test", 'Trim spaces from both sides');
    is(GitKttiUtils::trim("\ttest\t"), "test", 'Trim tabs from both sides');
    is(GitKttiUtils::trim(" \t test \t "), "test", 'Trim mixed whitespace');
    is(GitKttiUtils::trim("test"), "test", 'No trimming needed');
};

# Test de la fonction directoryExists (avec un répertoire temporaire)
subtest 'Directory existence tests' => sub {
    plan tests => 2;

    # Test avec le répertoire courant (doit exister)
    ok(GitKttiUtils::directoryExists(".", "t"), 'Directory t exists in current directory');

    # Test avec un répertoire qui n'existe pas
    ok(!GitKttiUtils::directoryExists(".", "nonexistent_directory_xyz"), 'Nonexistent directory returns false');
};

# Test de la fonction launch (commandes simples et sûres)
subtest 'Launch function tests' => sub {
    plan tests => 4;

    my $state;

    # Test avec une commande simple qui réussit
    my @result = GitKttiUtils::launch("echo 'test'", \$state);
    is($state, 0, 'Successful command returns 0 state');
    is($result[0], "test", 'Command output is correct');

    # Test avec une commande vide
    @result = GitKttiUtils::launch("", \$state);
    is($state, 99, 'Empty command returns error state');
    is(scalar @result, 0, 'Empty command returns empty array');
};

# Tests pour les fonctions Git (tests unitaires sans vraie interaction Git)
subtest 'Git utility function structure tests' => sub {
    plan tests => 10;

    # Vérifier que les fonctions Git existent
    can_ok('GitKttiUtils', 'git_getCurrentBranch');
    can_ok('GitKttiUtils', 'git_getGitRootDirectory');
    can_ok('GitKttiUtils', 'git_isRepoClean');
    can_ok('GitKttiUtils', 'git_getTrackedRemoteBranch');
    can_ok('GitKttiUtils', 'git_checkoutBranch');
    can_ok('GitKttiUtils', 'git_checkoutBranchNoConfirm');
    can_ok('GitKttiUtils', 'git_deleteLocalBranch');
    can_ok('GitKttiUtils', 'git_getLocalBranchesFilter');
    can_ok('GitKttiUtils', 'git_getRemoteBranchesFilter');
    can_ok('GitKttiUtils', 'git_getAllBranchesFilter');
};

# Test de validation des fonctions interactives (sans interaction réelle)
subtest 'Interactive function structure tests' => sub {
    plan tests => 3;

    can_ok('GitKttiUtils', 'isResponseYes');
    can_ok('GitKttiUtils', 'getResponse');
    can_ok('GitKttiUtils', 'getSelectResponse');
};

# Tests des fonctions rsync/scp (vérification de structure)
subtest 'Remote sync function structure tests' => sub {
    plan tests => 3;

    can_ok('GitKttiUtils', 'super_scp');
    can_ok('GitKttiUtils', 'super_rsync_ssh');
    can_ok('GitKttiUtils', 'super_rsync_ssh_with_exclude');
};

# Test de la fonction showVersion (capture de sortie)
subtest 'Version display test' => sub {
    plan tests => 1;

    # Capturer la sortie de showVersion
    my $output;
    {
        local *STDOUT;
        open(STDOUT, '>', \$output) or die "Can't redirect STDOUT: $!";
        GitKttiUtils::showVersion();
        close(STDOUT);
    }

    like($output, qr/gitktti v\d+\.\d+\.\d+/, 'showVersion displays correct format');
};

done_testing();
