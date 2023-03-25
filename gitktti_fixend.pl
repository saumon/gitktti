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
  print "usage:   perl gitktti_fixend.pl [--help] [--force] [--mode (hotfix|feature|release)]\n";
  print "example: perl gitktti_fixend.pl --force\n";
  print "         perl gitktti_fixend.pl --mode hotfix\n";
  print "         perl gitktti_fixend.pl -m feature\n";
  exit(0);
}

## arg : --mode
if ( $arg_mode ) {
  if($arg_mode !~ /^(${\(MODE_HOTFIX)}|${\(MODE_FEATURE)}|${\(MODE_RELEASE)})$/) {
    die "ERR : mode must be 'hotfix' or 'feature' or 'release'!\n";
  }
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
    die "ERROR: specified '" . $arg_mode . "' mode but your are on " . $develop_branch . " branch #weird!\n";
  }

  ## Tag name
  $tagname = ""; ## See later..

  ## Type of branch : develop
  $type_of_branch = $arg_mode;
}
else {
  die "ERROR: not on hotfix/release/" . $develop_branch . " branch !\n";
}

## Get tracked remote branch...
my %tracked_branch = GitKttiUtils::git_getTrackedRemoteBranch(\$ret);

print("\n");
print("Master branch   = [$master_branch]\n");
print("Develop branch  = [$develop_branch]\n");
print("Branch          = [$current_branch]\n");
print("Current repo    = [$current_repo]\n");
print("tracked[remote] = [" . $tracked_branch{"remote"} . "]\n");
print("tracked[branch] = [" . $tracked_branch{"branch"} . "]\n");
if($tagname ne "") { print("Tagname         = [$tagname]\n"); }
print("\n");

if ( GitKttiUtils::isResponseYes("Finalize $type_of_branch branch [$current_branch]?") ) {

  ## Check if repository is clean
  if ( !GitKttiUtils::git_isRepoClean() ) {
    print("ERROR: Your repository is not clean motherfucker ! Aborted !\n");
    exit(2);
  }

  ## Warning when finalizing 'develop' branch...
  if ( $type_of_branch eq MODE_DEVELOP ) {
    if ( !GitKttiUtils::isResponseYes("! WARNING ! You are on $develop_branch branch. All current developments will be merged into $master_branch branch. Are you sure?") ||
         !GitKttiUtils::isResponseYes("! WARNING ! Are you sure to be sure?") ) {
      print("ERROR: You are not sure ! Aborted !\n");
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
        print("ERROR: You need first to checkout release branch among these :\n\n");
        for my $branch (@releases_remote) { print ("$branch\n"); }
        print("\nAborted !\n");
        exit(2);
      }

      ## List local release branches
      $release_branch = GitKttiUtils::getSelectResponse("WARNING: The repository contains a release branch. Hotfix must be merged into release, NOT into develop !\n\nIn wich release branch do you want to merge '" . $current_branch . "' dumbass?", @releases_local);

      ## Merge current branch into selected local release branch
      $merge_done = GitKttiUtils::git_mergeIntoBranch($release_branch, $current_branch);

      ## This merge is mandatory !
      if ( !$merge_done ) {
        print("ERROR: current hotfix not merged in release ! Aborted !\n");
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
    print("You are on a '" . MODE_FEATURE . "' branch. Merge into $master_branch forbidden !\n");
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
          print("Not on [$master_branch] branch !\n");
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
  print("END : aborted !\n");
}
