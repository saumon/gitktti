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

my $arg_help     = "";
my $arg_name     = "";
my $ret          = 99;
my $current_branch = "";
my $new_branch   = "";
my $old_branch   = "";

## Args reading...
GetOptions ('help' => \$arg_help, 'name=s' => \$arg_name);

## arg : --help
if ( $arg_help ) {
  GitKttiUtils::printSection("HELP - GitKtti Move");
  print(GitKttiUtils::BRIGHT_WHITE . "Usage:" . GitKttiUtils::RESET . "\n");
  print("   perl gitktti_move.pl [--help] [--name new-branch-name]\n\n");

  GitKttiUtils::printSubSection("Description");
  print("This script allows you to rename the current local branch and its remote counterpart.\n");
  print("It will perform the following operations:\n");
  print("  1. Rename the local branch\n");
  print("  2. Push the new branch to remote\n");
  print("  3. Delete the old remote branch\n");
  print("  4. Set upstream tracking for the new branch\n\n");

  GitKttiUtils::printSubSection("Examples");
  GitKttiUtils::printCommand("perl gitktti_move.pl --name feature/user-authentication");
  GitKttiUtils::printCommand("perl gitktti_move.pl -n hotfix/critical-bug-fix");
  exit(0);
}

## Get current branch...
$current_branch = GitKttiUtils::git_getCurrentBranch(\$ret);

## Exit if we're on master or develop branch
if ( $current_branch =~ REGEX_MASTER || $current_branch =~ REGEX_DEVELOP ) {
  GitKttiUtils::printError("Cannot rename master or develop branch!");
  exit(1);
}

## Get tracked remote branch...
my %tracked_branch = GitKttiUtils::git_getTrackedRemoteBranch(\$ret);

GitKttiUtils::printSection("Branch Rename Configuration");

print(GitKttiUtils::BRIGHT_WHITE . "Current branch: " . GitKttiUtils::RESET);
GitKttiUtils::printBranch($current_branch);
print("\n");

if ( $tracked_branch{"remote"} ne "" && $tracked_branch{"branch"} ne "" ) {
  print(GitKttiUtils::BRIGHT_WHITE . "Remote:         " . GitKttiUtils::RESET . GitKttiUtils::CYAN . $tracked_branch{"remote"} . GitKttiUtils::RESET . "\n");
  print(GitKttiUtils::BRIGHT_WHITE . "Remote branch:  " . GitKttiUtils::RESET . GitKttiUtils::CYAN . $tracked_branch{"branch"} . GitKttiUtils::RESET . "\n");
}
else {
  print(GitKttiUtils::BRIGHT_WHITE . "Remote:         " . GitKttiUtils::RESET . GitKttiUtils::DIM . "No remote tracking" . GitKttiUtils::RESET . "\n");
}

## Get new branch name
if ( $arg_name ) {
  if ( $arg_name !~ /^[\w\/\-\.]+$/ ) {
    GitKttiUtils::printError("Invalid branch name! Use only letters, numbers, slashes, hyphens and dots.");
    exit(1);
  }
  $new_branch = $arg_name;
}
else {
  do {
    $new_branch = GitKttiUtils::getResponse("Enter new branch name:", $current_branch);

    if ( $new_branch !~ /^[\w\/\-\.]+$/ ) {
      GitKttiUtils::printError("Invalid branch name! Use only letters, numbers, slashes, hyphens and dots.");
      $new_branch = "";
    }
    elsif ( $new_branch eq $current_branch ) {
      GitKttiUtils::printWarning("New branch name is the same as current branch!");
      $new_branch = "";
    }
  } while ( $new_branch eq "" );
}

## Check if new branch name already exists locally
my @existing_branches = GitKttiUtils::git_getLocalBranchesFilter("^" . quotemeta($new_branch) . "\$", \$ret);
if ( @existing_branches > 0 ) {
  GitKttiUtils::printError("Branch '$new_branch' already exists locally!");
  exit(1);
}

## Check if new branch name already exists on remote
if ( $tracked_branch{"remote"} ne "" ) {
  my @remote_branches = GitKttiUtils::git_getRemoteBranchesFilter($tracked_branch{"remote"}, "^" . quotemeta($tracked_branch{"remote"} . "/" . $new_branch) . "\$", \$ret);
  if ( @remote_branches > 0 ) {
    GitKttiUtils::printError("Branch '$new_branch' already exists on remote!");
    exit(1);
  }
}

print("\n");
print(GitKttiUtils::BRIGHT_WHITE . "New branch:     " . GitKttiUtils::RESET);
GitKttiUtils::printBranch($new_branch);
print("\n\n");

## Check if repository is clean
if ( !GitKttiUtils::git_isRepoClean() ) {
  GitKttiUtils::printError("Your repository is not clean! Please commit or stash your changes first.");
  exit(2);
}

## Show operations that will be performed
GitKttiUtils::printSubSection("Operations to be performed:");
print("  1. " . GitKttiUtils::CYAN . "git branch -m $current_branch $new_branch" . GitKttiUtils::RESET . "\n");

if ( $tracked_branch{"remote"} ne "" && $tracked_branch{"branch"} ne "" ) {
  print("  2. " . GitKttiUtils::CYAN . "git push " . $tracked_branch{"remote"} . " $new_branch" . GitKttiUtils::RESET . "\n");
  print("  3. " . GitKttiUtils::CYAN . "git push " . $tracked_branch{"remote"} . " --delete " . $tracked_branch{"branch"} . GitKttiUtils::RESET . "\n");
  print("  4. " . GitKttiUtils::CYAN . "git push --set-upstream " . $tracked_branch{"remote"} . " $new_branch" . GitKttiUtils::RESET . "\n");
}
else {
  GitKttiUtils::printInfo("No remote tracking configured, only local branch will be renamed.");
}

print("\n");

if ( GitKttiUtils::isResponseYes("Proceed with branch rename?") ) {

  ## Step 1: Rename local branch
  GitKttiUtils::printSubSection("Step 1: Renaming local branch");
  GitKttiUtils::launch("git branch -m $current_branch $new_branch", \$ret);

  if ( $ret ne 0 ) {
    GitKttiUtils::printError("Failed to rename local branch!");
    exit(2);
  }

  GitKttiUtils::printSuccess("Local branch renamed successfully!");

  ## Steps 2-4: Handle remote operations if remote tracking exists
  if ( $tracked_branch{"remote"} ne "" && $tracked_branch{"branch"} ne "" ) {

    ## Step 2: Push new branch to remote
    GitKttiUtils::printSubSection("Step 2: Pushing new branch to remote");
    GitKttiUtils::launch("git push " . $tracked_branch{"remote"} . " $new_branch", \$ret);

    if ( $ret ne 0 ) {
      GitKttiUtils::printError("Failed to push new branch to remote!");
      GitKttiUtils::printWarning("Local branch has been renamed, but remote operations failed.");
      exit(2);
    }

    GitKttiUtils::printSuccess("New branch pushed to remote successfully!");

    ## Step 3: Delete old remote branch
    GitKttiUtils::printSubSection("Step 3: Deleting old remote branch");
    GitKttiUtils::launch("git push " . $tracked_branch{"remote"} . " --delete " . $tracked_branch{"branch"}, \$ret);

    if ( $ret ne 0 ) {
      GitKttiUtils::printWarning("Failed to delete old remote branch. You may need to delete it manually.");
    }
    else {
      GitKttiUtils::printSuccess("Old remote branch deleted successfully!");
    }

    ## Step 4: Set upstream tracking
    GitKttiUtils::printSubSection("Step 4: Setting upstream tracking");
    GitKttiUtils::launch("git push --set-upstream " . $tracked_branch{"remote"} . " $new_branch", \$ret);

    if ( $ret ne 0 ) {
      GitKttiUtils::printWarning("Failed to set upstream tracking. You may need to set it manually.");
    }
    else {
      GitKttiUtils::printSuccess("Upstream tracking set successfully!");
    }
  }

  GitKttiUtils::printSection("Branch Rename Complete");
  print(GitKttiUtils::BRIGHT_GREEN . "✅ Branch successfully renamed from " . GitKttiUtils::BOLD . $current_branch .
        GitKttiUtils::RESET . GitKttiUtils::BRIGHT_GREEN . " to " . GitKttiUtils::BOLD . $new_branch . GitKttiUtils::RESET . "\n");

  if ( $tracked_branch{"remote"} ne "" && $tracked_branch{"branch"} ne "" ) {
    print(GitKttiUtils::BRIGHT_GREEN . "✅ Remote branch operations completed" . GitKttiUtils::RESET . "\n");
  }

}
else {
  GitKttiUtils::printWarning("Operation cancelled!");
}
