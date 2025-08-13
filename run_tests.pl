#!/usr/bin/perl
##############################################################################
## Lanceur de tests pour GitKtti
## by ROBU
##############################################################################

use strict;
use warnings;
use FindBin qw($Bin);
use File::Find;
use Getopt::Long;

# Configuration
my $test_dir = "$Bin/t";
my $verbose = 0;
my $coverage = 0;
my $help = 0;

# Analyse des options de ligne de commande
GetOptions(
    'verbose|v'   => \$verbose,
    'coverage|c'  => \$coverage,
    'help|h'      => \$help,
) or die("Error in command line arguments\n");

if ($help) {
    print_help();
    exit(0);
}

print "=" x 80 . "\n";
print "GitKtti Test Suite Runner\n";
print "=" x 80 . "\n\n";

# Vérifier que le répertoire de tests existe
unless (-d $test_dir) {
    die("Test directory '$test_dir' not found!\n");
}

# Trouver tous les fichiers de test
my @test_files;
find(sub {
    push @test_files, $File::Find::name if /\.t$/;
}, $test_dir);

@test_files = sort @test_files;

if (@test_files == 0) {
    die("No test files found in '$test_dir'!\n");
}

print "Found " . scalar(@test_files) . " test files:\n";
for my $file (@test_files) {
    print "  - " . basename($file) . "\n";
}
print "\n";

# Exécuter les tests
my $total_tests = 0;
my $passed_tests = 0;
my $failed_tests = 0;
my @failed_files;

for my $test_file (@test_files) {
    print "Running " . basename($test_file) . "...\n";

    my $cmd = "perl";
    $cmd .= " -MDevel::Cover" if $coverage;
    $cmd .= " $test_file";

    my $output = `$cmd 2>&1`;
    my $exit_code = $? >> 8;

    if ($verbose || $exit_code != 0) {
        print $output;
    }

    # Analyser les résultats
    my $test_count = 0;
    my $passed_count = 0;
    my $failed_count = 0;

    # Compter le nombre de tests planifiés (format "1..N")
    if ($output =~ /^1\.\.(\d+)/m) {
        $test_count = $1;
        $total_tests += $test_count;
    }

    # Compter les tests qui ont réussi/échoué
    my @ok_lines = $output =~ /^(ok \d+|not ok \d+)/gm;
    my @not_ok_lines = $output =~ /^not ok \d+/gm;

    $failed_count = scalar(@not_ok_lines);
    $passed_count = $test_count - $failed_count;

    if ($exit_code == 0) {
        $passed_tests += $test_count;
        print "  ✓ PASSED ($test_count tests)\n";
    } else {
        $failed_tests += $test_count;
        push @failed_files, basename($test_file);
        print "  ✗ FAILED ($test_count tests, $failed_count failed)\n";
    }

    print "\n";
}

# Résumé final
print "=" x 80 . "\n";
print "TEST SUMMARY\n";
print "=" x 80 . "\n";
print "Total tests: $total_tests\n";
print "Passed:      $passed_tests\n";
print "Failed:      $failed_tests\n";

if (@failed_files) {
    print "\nFailed test files:\n";
    for my $file (@failed_files) {
        print "  - $file\n";
    }
}

if ($coverage) {
    print "\nCoverage report generated (if Devel::Cover is installed)\n";
    print "Run 'cover' to view the HTML coverage report\n";
}

print "\n";

# Code de sortie
my $exit_code = (@failed_files > 0) ? 1 : 0;
print "Tests " . ($exit_code == 0 ? "PASSED" : "FAILED") . "\n";
exit($exit_code);

# Fonctions utilitaires
sub basename {
    my $path = shift;
    $path =~ s/.*\/([^\/]+)$/$1/;
    return $path;
}

sub print_help {
    print "Usage: $0 [options]\n";
    print "\n";
    print "Options:\n";
    print "  -v, --verbose   Show detailed test output\n";
    print "  -c, --coverage  Generate coverage report (requires Devel::Cover)\n";
    print "  -h, --help      Show this help message\n";
    print "\n";
    print "Examples:\n";
    print "  $0                 # Run all tests quietly\n";
    print "  $0 --verbose       # Run all tests with detailed output\n";
    print "  $0 --coverage      # Run tests with coverage analysis\n";
}
