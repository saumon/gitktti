#! /usr/bin/perl
##############################################################################
## by ROBU
##############################################################################

use strict;
use warnings;
use File::Basename; ## For using 'basename'
use POSIX; ## For using 'strftime'
use GitKttiUtils;
use Getopt::Long;

use constant MODE_HOTFIX  => "hotfix";
use constant MODE_DEVELOP => "develop";
use constant MODE_RELEASE => "release";
use constant MODE_FEATURE => "feature";

use constant REGEX_HOTFIX  => '^(hotfix)_(.+)$';
use constant REGEX_DEVELOP => '^(dev|develop)$';
use constant REGEX_MASTER  => '^(master|main)$';
use constant REGEX_RELEASE => '^(release)_(.+)$';
use constant REGEX_FEATURE => '^(feature)_(.+)$';

GitKttiUtils::showVersion();

my $ret               = 99;
my $tagname           = "";
my $lasttag           = "";
my $tmp               = "";
my $target_branch     = "";
my $release_branch    = "";
my $master_branch     = "";
my $develop_branch    = "";
my $merge_done        = 99;
my $type_of_branch    = MODE_HOTFIX;
my $current_branch    = GitKttiUtils::git_getCurrentBranch(\$ret);
my $current_repo_path = GitKttiUtils::git_getGitRootDirectory();
my $current_repo      = basename($current_repo_path);
my $arg_help          = "";
my $arg_force         = "";
my $arg_mode          = "";
my @releases_local    = ();
my @releases_remote   = ();
my @develop_branches  = ();
my @master_branches   = ();

## Args reading...
GetOptions ('help' => \$arg_help, 'force' => \$arg_force, 'mode=s' => \$arg_mode);

## arg : --help
if ( $arg_help ) {
  GitKttiUtils::printSection("HELP - GitKtti Fix End");
  print(GitKttiUtils::BRIGHT_WHITE . "Usage:" . GitKttiUtils::RESET . "\n");
  print("   perl gitktti_fixend.pl [--help] [--force] [--mode (hotfix|feature|release)]\n\n");

  GitKttiUtils::printSubSection("Examples");
  GitKttiUtils::printCommand("perl gitktti_fixend.pl --force");
  GitKttiUtils::printCommand("perl gitktti_fixend.pl --mode hotfix");
  GitKttiUtils::printCommand("perl gitktti_fixend.pl -m feature");
  exit(0);
}

## arg : --mode
if ( $arg_mode ) {
  if($arg_mode !~ /^(${\(MODE_HOTFIX)}|${\(MODE_FEATURE)}|${\(MODE_RELEASE)})$/) {
    GitKttiUtils::printError("mode must be 'hotfix' or 'feature' or 'release'!");
    exit(1);
  }
}

## Get develop branch real name (locally)
@develop_branches = GitKttiUtils::git_getLocalBranchesFilter(REGEX_DEVELOP, \$ret);

if ( @develop_branches ne 1 ) {
  GitKttiUtils::printError("Develop branch not found or more than one! (looked for '" . REGEX_DEVELOP . "' ). Abort!");
  exit(2);
}
else {
  $develop_branch = $develop_branches[0];
}

## Get master branch real name (locally)
@master_branches = GitKttiUtils::git_getLocalBranchesFilter(REGEX_MASTER, \$ret);

if ( @master_branches ne 1 ) {
  GitKttiUtils::printError("Master branch not found or more than one! (looked for '" . REGEX_MASTER . "' ). Abort!");
  exit(2);
}
else {
  $master_branch = $master_branches[0];
}

if(!$arg_mode && $current_branch =~ /${\(REGEX_HOTFIX)}/) {
  ## Tag name
  $tagname = ""; ## See later..

  ## Type of branch : hotfix
  $type_of_branch = MODE_HOTFIX;
}
elsif(!$arg_mode && $current_branch =~ /${\(REGEX_RELEASE)}/) {
  ## Tag name
  $tagname = $2;

  ## Type of branch : release
  $type_of_branch = MODE_RELEASE;
}
elsif(!$arg_mode && $current_branch =~ /${\(REGEX_FEATURE)}/) {
  ## Tag name
  $tagname = ""; ## See later..

  ## Type of branch : feature
  $type_of_branch = MODE_FEATURE;
}
elsif(!$arg_mode && $current_branch =~ /${\(REGEX_DEVELOP)}/) {
  ## Tag name
  $tagname = ""; ## See later..

  ## Type of branch : develop
  $type_of_branch = MODE_DEVELOP;
}
elsif($arg_mode) {

  ## Special case: mode specified but you are on develop branch!
  if($current_branch =~ /${\(REGEX_DEVELOP)}/) {
    GitKttiUtils::printError("specified '" . $arg_mode . "' mode but your are on " . $develop_branch . " branch #weird!");
    exit(1);
  }

  ## Tag name
  $tagname = ""; ## See later..

  ## Type of branch : develop
  $type_of_branch = $arg_mode;
}
else {
  GitKttiUtils::printError("not on hotfix/release/" . $develop_branch . " branch !");
  exit(1);
}

## Get tracked remote branch...
my %tracked_branch = GitKttiUtils::git_getTrackedRemoteBranch(\$ret);

GitKttiUtils::printSection("Finalization Summary");

print(GitKttiUtils::BRIGHT_WHITE . "Master branch:  " . GitKttiUtils::RESET);
GitKttiUtils::printBranch($master_branch, "master");
print("\n");

print(GitKttiUtils::BRIGHT_WHITE . "Develop branch: " . GitKttiUtils::RESET);
GitKttiUtils::printBranch($develop_branch, "develop");
print("\n");

print(GitKttiUtils::BRIGHT_WHITE . "Current branch: " . GitKttiUtils::RESET);
if ($current_branch =~ /${\(REGEX_MASTER)}/) {
  GitKttiUtils::printBranch($current_branch, "master");
} elsif ($current_branch =~ /${\(REGEX_DEVELOP)}/) {
  GitKttiUtils::printBranch($current_branch, "develop");
} elsif ($current_branch =~ /${\(REGEX_FEATURE)}/) {
  GitKttiUtils::printBranch($current_branch, "feature");
} elsif ($current_branch =~ /${\(REGEX_HOTFIX)}/) {
  GitKttiUtils::printBranch($current_branch, "hotfix");
} elsif ($current_branch =~ /${\(REGEX_RELEASE)}/) {
  GitKttiUtils::printBranch($current_branch, "release");
} else {
  GitKttiUtils::printBranch($current_branch);
}
print("\n");

print(GitKttiUtils::BRIGHT_WHITE . "Repository:     " . GitKttiUtils::RESET . GitKttiUtils::CYAN . $current_repo . GitKttiUtils::RESET . "\n");
print(GitKttiUtils::BRIGHT_WHITE . "Remote:         " . GitKttiUtils::RESET . GitKttiUtils::CYAN . $tracked_branch{"remote"} . GitKttiUtils::RESET . "\n");
print(GitKttiUtils::BRIGHT_WHITE . "Tracked branch: " . GitKttiUtils::RESET . GitKttiUtils::CYAN . $tracked_branch{"branch"} . GitKttiUtils::RESET . "\n");

if($tagname ne "") {
  print(GitKttiUtils::BRIGHT_WHITE . "Tag name:       " . GitKttiUtils::RESET);
  GitKttiUtils::printTag($tagname);
  print("\n");
}
print("\n");

if ( GitKttiUtils::isResponseYes("Finalize $type_of_branch branch " . GitKttiUtils::BOLD . $current_branch . GitKttiUtils::RESET . "?") ) {

  ## Check if repository is clean
  if ( !GitKttiUtils::git_isRepoClean() ) {
    GitKttiUtils::printError("Your repository is not clean motherfucker ! Aborted !");
    exit(2);
  }

  ## Warning when finalizing 'develop' branch...
  if ( $type_of_branch eq MODE_DEVELOP ) {
    if ( !GitKttiUtils::isResponseYes("! WARNING ! You are on $develop_branch branch. All current developments will be merged into $master_branch branch. Are you sure?") ||
         !GitKttiUtils::isResponseYes("! WARNING ! Are you sure to be sure?") ) {
      GitKttiUtils::printError("You are not sure ! Aborted !");
      exit(2);
    }

    ## Pulls branch
    GitKttiUtils::git_pullCurrentBranch($tracked_branch{"remote"}, $tracked_branch{"branch"});
  }

  if ( $type_of_branch ne MODE_DEVELOP ) {

    ## Get local release branches
    @releases_local = GitKttiUtils::git_getLocalBranchesFilter(MODE_RELEASE, \$ret);

    ## Get remote release branches
    @releases_remote = GitKttiUtils::git_getRemoteBranchesFilter($tracked_branch{"remote"}, REGEX_RELEASE, \$ret);

    ## Special case : hotfix finalization when release in progress
    if ( ($type_of_branch eq MODE_HOTFIX) && (@releases_local > 0 || @releases_remote > 0) ) {

      ## Release branch must be checked out first !
      if ( @releases_local == 0 ) {
        GitKttiUtils::printError("You need first to checkout release branch among these :");
        print("\n");
        for my $branch (@releases_remote) { print ("$branch\n"); }
        GitKttiUtils::printError("Aborted !");
        exit(2);
      }

      ## List local release branches
      $release_branch = GitKttiUtils::getSelectResponse("WARNING: The repository contains a release branch. Hotfix must be merged into release, NOT into develop !\n\nIn wich release branch do you want to merge '" . $current_branch . "' dumbass?", @releases_local);

      ## Merge current branch into selected local release branch
      $merge_done = GitKttiUtils::git_mergeIntoBranch($release_branch, $current_branch);

      ## This merge is mandatory !
      if ( !$merge_done ) {
        GitKttiUtils::printError("current hotfix not merged in release ! Aborted !");
        exit(2);
      }

      ## Then, release branch should be merged into develop branch
      GitKttiUtils::git_mergeIntoBranch($develop_branch, $release_branch);
    }
    else {
      ## Merge current branch into develop
      $merge_done = GitKttiUtils::git_mergeIntoBranch($develop_branch, $current_branch);

      ## Possibility to merge into another local branch
      if ( !$merge_done && GitKttiUtils::isResponseYes("! Warning ! Merge into another local '" . $type_of_branch . "' branch?") && GitKttiUtils::isResponseYes("! WARNING ! Are you sure to be sure?") ) {

        ## List local branches
        $target_branch = GitKttiUtils::getSelectResponse("In wich branch do you want to merge '" . $current_branch . "' dumbass?", GitKttiUtils::git_getLocalBranchesFilter($type_of_branch, \$ret));

        ## Merge current branch into selected local branch
        GitKttiUtils::git_mergeIntoBranch($target_branch, $current_branch);
      }
    }
  }

  ## Merge into master forbidden for a feature !
  if ( $type_of_branch eq MODE_FEATURE ) {
    GitKttiUtils::printInfo("You are on a '" . MODE_FEATURE . "' branch. Merge into $master_branch forbidden !");
  }
  else {
    ## Merge current branch into master branch
    $merge_done = GitKttiUtils::git_mergeIntoBranch($master_branch, $current_branch);

    if ($merge_done) {

      ## Get last tag from current branch
      $lasttag = GitKttiUtils::git_getLastTagFromCurrentBranch(\$ret);

      if ( GitKttiUtils::isResponseYes("Last tag is [$lasttag]. Create and push a new tag?") ) {

        $tmp = GitKttiUtils::git_getCurrentBranch(\$ret);

        if ( $tmp =~ $master_branch ) {

          if ( $tagname ne "" ) {
            if (!GitKttiUtils::isResponseYes("Do you want to use new tag [$tagname]?") ) {
              $tagname = "";
            }
          }

          if ( $tagname eq "" ) {
            $tagname = GitKttiUtils::getResponse("Please enter tag value ('$lasttag' --> 'x.x.x') :");
          }

          ## Go tagging !
          GitKttiUtils::git_tagBranch($tmp, $tagname, $lasttag);
        }
        else {
          GitKttiUtils::printWarning("Not on [$master_branch] branch !");
        }
      }
    }
  }

  ## Delete current branch (not for 'develop' branch rofl)
  if ( $type_of_branch ne MODE_DEVELOP ) {
    GitKttiUtils::git_deleteCurrentBranch($current_branch, $tracked_branch{"remote"}, $tracked_branch{"branch"});
  }
}
else {
  GitKttiUtils::printWarning("Aborted !");
}
