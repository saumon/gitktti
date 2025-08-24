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
my $arg_force    = "";
my $ret          = 99;
my $current_branch = "";
my $target_branch = "";

## Args reading...
GetOptions ('help' => \$arg_help, 'name=s' => \$arg_name, 'force' => \$arg_force);

## arg : --help
if ( $arg_help ) {
  GitKttiUtils::printSection("HELP - GitKtti Delete");
  print(GitKttiUtils::BRIGHT_WHITE . "Usage:" . GitKttiUtils::RESET . "\n");
  print("   perl gitktti_delete.pl [--help] [--name branch-name] [--force]\n\n");

  GitKttiUtils::printSubSection("Description");
  print("This script allows you to delete a local branch and its remote counterpart.\n");
  print("It will perform the following operations:\n");
  print("  1. Switch to develop/master if currently on the target branch\n");
  print("  2. Delete the local branch\n");
  print("  3. Delete the remote branch (if it exists)\n\n");

  GitKttiUtils::printSubSection("Options");
  print("  --name      Specify the branch name to delete\n");
  print("  --force     Force deletion (use -D instead of -d for local branch)\n");
  print("  --help      Show this help message\n\n");

  GitKttiUtils::printSubSection("Examples");
  GitKttiUtils::printCommand("perl gitktti_delete.pl --name feature/user-authentication");
  GitKttiUtils::printCommand("perl gitktti_delete.pl -n hotfix/old-fix --force");
  GitKttiUtils::printCommand("perl gitktti_delete.pl");
  exit(0);
}

## Get current branch...
$current_branch = GitKttiUtils::git_getCurrentBranch(\$ret);

## Get target branch name
if ( $arg_name ) {
  if ( $arg_name !~ /^[\w\/\-\.]+$/ ) {
    GitKttiUtils::printError("Invalid branch name! Use only letters, numbers, slashes, hyphens and dots.");
    exit(1);
  }
  $target_branch = $arg_name;
}
else {
  ## Show available local branches (excluding master/develop)
  my @local_branches = GitKttiUtils::git_getLocalBranches(\$ret);
  my @filtered_branches = ();

  foreach my $branch (@local_branches) {
    if ( $branch !~ REGEX_MASTER && $branch !~ REGEX_DEVELOP ) {
      push @filtered_branches, $branch;
    }
  }

  if ( @filtered_branches == 0 ) {
    GitKttiUtils::printInfo("No feature branches found to delete.");
    exit(0);
  }

  ## List local branches with selector
  $target_branch = GitKttiUtils::getSelectResponse("Which branch to delete?", @filtered_branches);
}

## Protect master and develop branches
if ( $target_branch =~ REGEX_MASTER || $target_branch =~ REGEX_DEVELOP ) {
  GitKttiUtils::printError("Cannot delete master or develop branch!");
  exit(1);
}

## Check if target branch exists locally
my @existing_branches = GitKttiUtils::git_getLocalBranchesFilter("^" . quotemeta($target_branch) . "\$", \$ret);
if ( @existing_branches == 0 ) {
  GitKttiUtils::printError("Branch '$target_branch' does not exist locally!");
  exit(1);
}

## Get tracked remote branch for the target branch
my %tracked_branch = ();
if ( $target_branch eq $current_branch ) {
  %tracked_branch = GitKttiUtils::git_getTrackedRemoteBranch(\$ret);
}
else {
  ## Switch temporarily to get remote info
  GitKttiUtils::launch("git checkout $target_branch", \$ret);
  if ( $ret == 0 ) {
    %tracked_branch = GitKttiUtils::git_getTrackedRemoteBranch(\$ret);
    GitKttiUtils::launch("git checkout $current_branch", \$ret);
  }
}

GitKttiUtils::printSection("Branch Deletion Configuration");

print(GitKttiUtils::BRIGHT_WHITE . "Target branch:  " . GitKttiUtils::RESET);
GitKttiUtils::printBranch($target_branch);
print("\n");

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

print(GitKttiUtils::BRIGHT_WHITE . "Force delete:   " . GitKttiUtils::RESET . ($arg_force ? GitKttiUtils::BRIGHT_RED . "YES" : GitKttiUtils::DIM . "NO") . GitKttiUtils::RESET . "\n");

print("\n");

## Check if repository is clean (only if we need to switch branches)
if ( $target_branch eq $current_branch ) {
  if ( !GitKttiUtils::git_isRepoClean() ) {
    GitKttiUtils::printError("Your repository is not clean! Please commit or stash your changes first.");
    exit(2);
  }
}

## Show operations that will be performed
GitKttiUtils::printSubSection("Operations to be performed:");

my $step = 1;
if ( $target_branch eq $current_branch ) {
  print("  $step. " . GitKttiUtils::CYAN . "git checkout develop" . GitKttiUtils::RESET . " (switch away from target branch)\n");
  $step++;
}

my $delete_flag = $arg_force ? "-D" : "-d";
print("  $step. " . GitKttiUtils::CYAN . "git branch $delete_flag $target_branch" . GitKttiUtils::RESET . "\n");
$step++;

if ( $tracked_branch{"remote"} ne "" && $tracked_branch{"branch"} ne "" ) {
  print("  $step. " . GitKttiUtils::CYAN . "git push " . $tracked_branch{"remote"} . " --delete " . $tracked_branch{"branch"} . GitKttiUtils::RESET . "\n");
}
else {
  GitKttiUtils::printInfo("No remote tracking configured, only local branch will be deleted.");
}

print("\n");

if ( GitKttiUtils::isResponseYes("Proceed with branch deletion?") ) {

  my $step_num = 1;

  ## Step 1: Switch away from target branch if needed
  if ( $target_branch eq $current_branch ) {
    GitKttiUtils::printSubSection("Step $step_num: Switching to develop branch");

    ## Try to switch to develop first, then master if develop doesn't exist
    GitKttiUtils::launch("git checkout develop", \$ret);
    if ( $ret ne 0 ) {
      GitKttiUtils::launch("git checkout master", \$ret);
      if ( $ret ne 0 ) {
        GitKttiUtils::launch("git checkout main", \$ret);
        if ( $ret ne 0 ) {
          GitKttiUtils::printError("Failed to switch to develop/master/main branch!");
          exit(2);
        }
      }
    }

    GitKttiUtils::printSuccess("Switched away from target branch!");
    $step_num++;
  }

  ## Step 2: Delete local branch
  GitKttiUtils::printSubSection("Step $step_num: Deleting local branch");
  GitKttiUtils::launch("git branch $delete_flag $target_branch", \$ret);

  if ( $ret ne 0 ) {
    GitKttiUtils::printError("Failed to delete local branch!");
    if ( !$arg_force ) {
      GitKttiUtils::printInfo("Try using --force flag if the branch is not fully merged.");
    }
    exit(2);
  }

  GitKttiUtils::printSuccess("Local branch deleted successfully!");
  $step_num++;

  ## Step 3: Delete remote branch if it exists
  if ( $tracked_branch{"remote"} ne "" && $tracked_branch{"branch"} ne "" ) {
    GitKttiUtils::printSubSection("Step $step_num: Deleting remote branch");
    GitKttiUtils::launch("git push " . $tracked_branch{"remote"} . " --delete " . $tracked_branch{"branch"}, \$ret);

    if ( $ret ne 0 ) {
      GitKttiUtils::printWarning("Failed to delete remote branch. It may have already been deleted or you may not have permission.");
    }
    else {
      GitKttiUtils::printSuccess("Remote branch deleted successfully!");
    }
  }

  GitKttiUtils::printSection("Branch Deletion Complete");
  print(GitKttiUtils::BRIGHT_GREEN . "✅ Branch " . GitKttiUtils::BOLD . $target_branch . GitKttiUtils::RESET . GitKttiUtils::BRIGHT_GREEN . " deleted successfully" . GitKttiUtils::RESET . "\n");

  if ( $tracked_branch{"remote"} ne "" && $tracked_branch{"branch"} ne "" ) {
    print(GitKttiUtils::BRIGHT_GREEN . "✅ Remote branch operations completed" . GitKttiUtils::RESET . "\n");
  }

}
else {
  GitKttiUtils::printWarning("Operation cancelled!");
}
