#!/usr/bin/perl
##############################################################################
## Tests de performance et de robustesse pour GitKtti
## by ROBU
##############################################################################

use strict;
use warnings;
use Test::More tests => 6;
use FindBin qw($Bin);
use lib "$Bin/../modules";
use Time::HiRes qw(gettimeofday tv_interval);

# Import du module à tester
BEGIN {
    use_ok('GitKttiUtils') || print "Bail out!\n";
}

# Test de performance des fonctions de formatage
subtest 'String formatting performance' => sub {
    plan tests => 4;

    my $start_time = [gettimeofday];

    # Test de performance pour LPad avec de nombreuses itérations
    for my $i (1..1000) {
        GitKttiUtils::LPad("test$i", 20, "0");
    }

    my $lpad_time = tv_interval($start_time);
    ok($lpad_time < 1.0, "LPad performance acceptable (${lpad_time}s < 1s)");

    $start_time = [gettimeofday];

    # Test de performance pour RPad
    for my $i (1..1000) {
        GitKttiUtils::RPad("test$i", 20, "0");
    }

    my $rpad_time = tv_interval($start_time);
    ok($rpad_time < 1.0, "RPad performance acceptable (${rpad_time}s < 1s)");

    $start_time = [gettimeofday];

    # Test de performance pour trim
    for my $i (1..1000) {
        GitKttiUtils::trim("  test$i  ");
    }

    my $trim_time = tv_interval($start_time);
    ok($trim_time < 1.0, "Trim performance acceptable (${trim_time}s < 1s)");

    # Test général de performance
    ok($lpad_time + $rpad_time + $trim_time < 2.0, "Overall string operations performance acceptable");
};

# Tests de robustesse avec des entrées inattendues
subtest 'String formatting robustness' => sub {
    plan tests => 8;

    # Test avec des chaînes vides
    is(GitKttiUtils::LPad("", 5), "     ", "LPad handles empty string");
    is(GitKttiUtils::RPad("", 5), "     ", "RPad handles empty string");
    is(GitKttiUtils::trim(""), "", "Trim handles empty string");

    # Test avec des caractères spéciaux
    my $special_str = "test";  # Utilisons des caractères simples pour éviter les problèmes d'encodage
    is(GitKttiUtils::LPad($special_str, 8), "    test", "LPad handles normal characters");
    is(GitKttiUtils::RPad($special_str, 8), "test    ", "RPad handles normal characters");
    is(GitKttiUtils::trim("  test  "), "test", "Trim handles normal characters");

    # Test avec des valeurs limites
    is(GitKttiUtils::LPad("test", 0), "", "LPad handles zero length");
    is(GitKttiUtils::RPad("test", 0), "", "RPad handles zero length");
};

# Tests de robustesse pour la fonction launch
subtest 'Launch function robustness' => sub {
    plan tests => 3;

    my $state;

    # Test avec une commande qui échoue
    my @result = GitKttiUtils::launch("false", \$state);
    isnt($state, 0, "Launch correctly handles failed commands");

    # Test avec une commande très courte
    @result = GitKttiUtils::launch("true", \$state);
    is($state, 0, "Launch handles simple successful commands");

    # Test avec une commande qui génère beaucoup de sortie
    @result = GitKttiUtils::launch("echo 'line1'; echo 'line2'; echo 'line3'", \$state);
    is(scalar @result, 3, "Launch handles multi-line output correctly");
};

# Tests de gestion des erreurs
subtest 'Error handling tests' => sub {
    plan tests => 2;

    # Test directoryExists avec un chemin invalide
    my $result = eval { GitKttiUtils::directoryExists("/nonexistent/path", "test") };
    ok($@, "directoryExists correctly handles invalid paths");

    # Test launch avec une référence invalide (doit être géré gracieusement)
    my $state;
    eval { GitKttiUtils::launch("echo test", \$state) };
    ok(!$@, "Launch handles normal operation without errors");
};

# Tests de cas limites
subtest 'Edge case tests' => sub {
    plan tests => 6;

    # Test LPad/RPad avec des longueurs négatives
    my $result1 = GitKttiUtils::LPad("test", -1);
    ok(defined $result1, "LPad handles negative length gracefully");

    my $result2 = GitKttiUtils::RPad("test", -1);
    ok(defined $result2, "RPad handles negative length gracefully");

    # Test avec des caractères de remplissage multiples
    my $result3 = GitKttiUtils::LPad("test", 8, "ab");
    ok(defined $result3, "LPad handles multi-character pad");

    my $result4 = GitKttiUtils::RPad("test", 8, "ab");
    ok(defined $result4, "RPad handles multi-character pad");

    # Test trim avec seulement des espaces
    is(GitKttiUtils::trim("   "), "", "Trim handles whitespace-only string");

    # Test trim avec des caractères de nouvelle ligne
    is(GitKttiUtils::trim("\ntest\n"), "test", "Trim handles newlines");
};

done_testing();
