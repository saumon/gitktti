#!/usr/bin/perl
##############################################################################
## Tests de validation des scripts GitKtti
## by ROBU
##############################################################################

use strict;
use warnings;
use Test::More;
use FindBin qw($Bin);

# Liste des scripts à tester
my @scripts = (
    'gitktti_checkout.pl',
    'gitktti_fix.pl',
    'gitktti_fixend.pl',
    'gitktti_tag.pl',
    'gitktti_tests.pl'
);

plan tests => scalar(@scripts);

# Test pour chaque script
for my $script (@scripts) {
    my $script_path = "$Bin/../$script";

    subtest "Testing script: $script" => sub {
        plan tests => 3;

        # Test 1: Le fichier existe
        ok(-f $script_path, "$script exists");

        # Test 2: Le fichier est exécutable
        ok(-x $script_path, "$script is executable");

        # Test 3: Syntaxe Perl valide
        my $syntax_check = `perl -c $script_path 2>&1`;
        my $exit_code = $? >> 8;

        is($exit_code, 0, "$script has valid Perl syntax");

        if ($exit_code != 0) {
            diag("Syntax error in $script: $syntax_check");
        }
    };
}

done_testing();
