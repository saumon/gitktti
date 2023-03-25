#! /usr/bin/perl
##############################################################################
## by ROBU
##############################################################################

use strict;
use warnings;
use File::Basename; ## For using 'basename'
use Getopt::Long;
use GitKttiUtils;

use constant REGEX_DEVELOP => '^(dev|develop)$';
use constant REGEX_MASTER  => '^(master|main)$';

GitKttiUtils::showVersion();

my $arg_help        = "";
my $arg_filter      = "";
my $arg_delete      = "";
my $ret             = 99;
my $current_branch  = "";
my $local_branch    = "";
my $remote_branch   = "";
my $master_branch   = "";
my $develop_branch  = "";
my $deleted         = 0;
my @local_branches  = ();
my @remote_branches = ();
my @develop_branches  = ();
my @master_branches   = ();

## Args reading...
GetOptions ('help' => \$arg_help, 'filter=s' => \$arg_filter, 'delete' => \$arg_delete);

## arg : --help
if ( $arg_help ) {
  print "usage:   perl gitktti_checkout.pl [--help] [--filter filter] [--delete]\n";
  print "example: perl gitktti_checkout.pl --filter G401-750 --delete\n";
  print "example: perl gitktti_checkout.pl -f EARTH -d\n";
  exit(0);
}

## Get develop branch real name (locally)
@develop_branches = GitKttiUtils::git_getLocalBranchesFilter(REGEX_DEVELOP, \$ret);

if ( @develop_branches ne 1 ) {
  print("ERROR: Develop branch not found or more than one! (looked for '" . REGEX_DEVELOP . "' ). Abort!\n");
  exit(2);
}
else {
  $develop_branch = $develop_branches[0];
}

## Get master branch real name (locally)
@master_branches = GitKttiUtils::git_getLocalBranchesFilter(REGEX_MASTER, \$ret);

if ( @master_branches ne 1 ) {
  print("ERROR: Master branch not found or more than one! (looked for '" . REGEX_MASTER . "' ). Abort!\n");
  exit(2);
}
else {
  $master_branch = $master_branches[0];
}

## Get tracked remote branch...
my %tracked_branch = GitKttiUtils::git_getTrackedRemoteBranch(\$ret);

## Get current branch...
$current_branch = GitKttiUtils::git_getCurrentBranch(\$ret);

## Get local branches (filtered by name)
@local_branches = GitKttiUtils::git_getLocalBranchesFilter($arg_filter, \$ret);

if ( @local_branches > 0 ) {
  ## List local branches
  $local_branch = GitKttiUtils::getSelectResponse("Which local branch?", @local_branches);

  ## Special case : you already are on the branch you want to switch to...
  if ( $local_branch eq $current_branch ) {

    ## The only reason to switch is when you want to delete your branch
    if ( $arg_delete ) {
      print("WARNING: you already are on this branch, need to switch to '$develop_branch' or '$master_branch' in order to delete it...\n");

      GitKttiUtils::git_checkoutBranchNoConfirm(
          GitKttiUtils::getSelectResponse("Where to?", $develop_branch, $master_branch)
      );
    }
    else {
      print("You already are on this branch!\n");
      exit(0);
    }
  }

  if ( $arg_delete ) {
    ## Delete branch ?
    $deleted = GitKttiUtils::git_deleteLocalBranch($local_branch);
  }

  ## Checkout selected local branch
  if ( !$deleted ) {
    GitKttiUtils::git_checkoutBranchNoConfirm($local_branch);

    ## Done
    exit(0);
  }
}
else {
  print("Local branch not found !\n");
}

## Fetch...
if ( $tracked_branch{"remote"} ne "" && GitKttiUtils::isResponseYes("Fetch from remote '" . $tracked_branch{"remote"} . "'?") ) {
  GitKttiUtils::git_fetch(\$ret);
}

## Get remote branches (filtered by name)
@remote_branches = GitKttiUtils::git_getRemoteBranchesFilter($tracked_branch{"remote"}, $arg_filter, \$ret);

if ( @remote_branches > 0 ) {
  ## List remote branches
  $remote_branch = GitKttiUtils::getSelectResponse("Which remote branch?", @remote_branches);

  if ( $remote_branch =~ /^$tracked_branch{"remote"}\/(.+)$/ ) {
    GitKttiUtils::git_checkoutBranchNoConfirm($1);
  }
  else {
    print("ERROR: unexpected error !\n");
    exit(2);
  }
}
else {
  print("No remote branch found.\n");
}
