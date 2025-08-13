#!/usr/bin/perl
##############################################################################
## Tests d'intégration pour les scripts GitKtti
## by ROBU
##############################################################################

use strict;
use warnings;
use Test::More;
use FindBin qw($Bin);
use lib "$Bin/../modules";
use File::Temp qw(tempdir);
use Cwd qw(cwd);

# Import des modules
BEGIN {
    use_ok('GitKttiUtils') || print "Bail out!\n";
}

# Vérifier si nous sommes dans un repository Git
my $original_dir = cwd();
my $ret;
my $git_root = eval { GitKttiUtils::git_getGitRootDirectory() };

if ($@) {
    plan skip_all => "Not in a Git repository, skipping Git integration tests";
} else {
    plan tests => 9;
}

# Tests d'intégration Git (nécessitent un vrai repository)
subtest 'Git repository detection' => sub {
    plan tests => 2;

    ok(defined $git_root, 'Git root directory detected');
    ok(-d $git_root, 'Git root directory exists');
};

subtest 'Git current branch detection' => sub {
    plan tests => 2;

    my $current_branch = GitKttiUtils::git_getCurrentBranch(\$ret);

    ok(defined $current_branch, 'Current branch is detected');
    is($ret, 0, 'git_getCurrentBranch succeeds');
};

subtest 'Git repository status' => sub {
    plan tests => 1;

    my $is_clean = GitKttiUtils::git_isRepoClean();

    ok(defined $is_clean, 'Repository cleanliness status is determined');
    note("Repository is " . ($is_clean ? "clean" : "dirty"));
};

subtest 'Git tracked remote branch' => sub {
    plan tests => 2;

    my %tracked = GitKttiUtils::git_getTrackedRemoteBranch(\$ret);

    ok(exists $tracked{"remote"}, 'Remote key exists in tracked branch hash');
    ok(exists $tracked{"branch"}, 'Branch key exists in tracked branch hash');

    if ($tracked{"remote"} && $tracked{"branch"}) {
        note("Tracking: " . $tracked{"remote"} . "/" . $tracked{"branch"});
    }
};

subtest 'Git fetch operations' => sub {
    plan tests => 3;

    # Test git_fetch function existence and basic functionality
    can_ok('GitKttiUtils', 'git_fetch');
    can_ok('GitKttiUtils', 'git_fetchTags');
    can_ok('GitKttiUtils', 'git_fetchPrune');
};

subtest 'Git branch listing' => sub {
    plan tests => 3;

    # Vérifier que les fonctions existent
    can_ok('GitKttiUtils', 'git_getLocalBranchesFilter');
    can_ok('GitKttiUtils', 'git_getRemoteBranchesFilter');
    can_ok('GitKttiUtils', 'git_getAllBranchesFilter');
};

subtest 'Git tag operations' => sub {
    plan tests => 4;

    can_ok('GitKttiUtils', 'git_getLastTagFromAllBranches');
    can_ok('GitKttiUtils', 'git_getLastTagFromCurrentBranch');
    can_ok('GitKttiUtils', 'git_cleanLocalTags');
    can_ok('GitKttiUtils', 'git_tagBranch');
};

subtest 'Git parent branch detection' => sub {
    plan tests => 1;

    can_ok('GitKttiUtils', 'git_getParentBranch');
};

done_testing();
