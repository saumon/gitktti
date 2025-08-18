#! /usr/bin/perl
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
my $deleted         = 0;
my @local_branches  = ();
my @remote_branches = ();
my @develop_branches  = ();
my @master_branches   = ();
my @local_dev_or_master_branches = ();

## Args reading...
GetOptions ('help' => \$arg_help, 'filter=s' => \$arg_filter, 'delete' => \$arg_delete);

## arg : --help
if ( $arg_help ) {
  GitKttiUtils::printSection("HELP - GitKtti Checkout");
  print(GitKttiUtils::BRIGHT_WHITE . "Usage:" . GitKttiUtils::RESET . "\n");
  print("   perl gitktti_checkout.pl [--help] [--filter filter] [--delete]\n\n");

  GitKttiUtils::printSubSection("Examples");
  GitKttiUtils::printCommand("perl gitktti_checkout.pl --filter badbranch --delete");
  GitKttiUtils::printCommand("perl gitktti_checkout.pl -f badbranch -d");
  exit(0);
}

## Get develop branch real name (locally)
@develop_branches = GitKttiUtils::git_getLocalBranchesFilter(REGEX_DEVELOP, \$ret);

## Get master branch real name (locally)
@master_branches = GitKttiUtils::git_getLocalBranchesFilter(REGEX_MASTER, \$ret);

@local_dev_or_master_branches = (@develop_branches, @master_branches);

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
      GitKttiUtils::printWarning("you already are on this branch, need to switch to another in order to delete it...");

      if ( @local_dev_or_master_branches > 0 ) {
        ## Checkout develop or master branch
        GitKttiUtils::git_checkoutBranchNoConfirm(
          GitKttiUtils::getSelectResponse("Where to?", @local_dev_or_master_branches)
        );
      }
      else {
        GitKttiUtils::printError("No develop or master branches found !");
        exit(1);
      }
    }
    else {
      GitKttiUtils::printInfo("You already are on this branch!");
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
  GitKttiUtils::printWarning("Local branch not found !");
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
    GitKttiUtils::printError("unexpected error !");
    exit(2);
  }
}
else {
  GitKttiUtils::printInfo("No remote branch found.");
}
