#! /usr/bin/perl
##############################################################################
## by ROBU
##############################################################################

use strict;
use warnings;
use POSIX; ## For using 'strftime'
use Getopt::Long;
use GitKttiUtils;
use constant MODE_HOTFIX  => "hotfix";
use constant MODE_FEATURE => "feature";
use constant MODE_RELEASE => "release";

use constant REGEX_HOTFIX  => '^(hotfix)_(.+)$';
use constant REGEX_DEVELOP => '^(dev|develop)$';
use constant REGEX_MASTER  => '^(master|main)$';
use constant REGEX_RELEASE => '^(release)_(.+)$';
use constant REGEX_FEATURE => '^(feature)_(.+)$';

GitKttiUtils::showVersion();

my $ret            = 99;
my $lasttag        = "";
my $lasttag_maj    = "";
my $lasttag_min    = "";
my $lasttag_patch  = "";
my $new_branch     = "";
my $prefix_branch  = "";
my $suffix_branch  = "";
my $current_branch = "";
my $arg_help       = "";
my $arg_tag        = "";
my $arg_name       = "";
my $arg_mode       = "";
my $arg_prune      = "";
my $arg_zeroprefix = "";
my $mode           = MODE_HOTFIX;

## Args reading...
GetOptions ('help' => \$arg_help, 'tag=s' => \$arg_tag, 'name=s' => \$arg_name, 'mode=s' => \$arg_mode, 'prune' => \$arg_prune, 'zeroprefix' => \$arg_zeroprefix);

## arg : --help
if ( $arg_help ) {
  print "usage:   perl gitktti_fix.pl [--help] [--tag JIRATAG] [--name name] [--mode (hotfix|feature|release)] [--prune] [--zeroprefix]\n";
  print "example: perl gitktti_fix.pl -t PB-1233 --zeroprefix\n";
  print "         perl gitktti_fix.pl -n coucou\n";
  print "         perl gitktti_fix.pl -m feature\n";
  print "         perl gitktti_fix.pl -m feature -t EARTH-1234 --z\n";
  print "         perl gitktti_fix.pl -m feature -n coucou\n";
  print "         perl gitktti_fix.pl -m release\n";
  print "         perl gitktti_fix.pl --prune\n";
  exit(0);
}

## Get tracked remote branch...
my %tracked_branch = GitKttiUtils::git_getTrackedRemoteBranch(\$ret);

## arg : --prune
if ( $arg_prune ) {
  if ( GitKttiUtils::isResponseYes("Do you want to clean your local branches?") ) {
    GitKttiUtils::git_fetchPrune(\$ret);

    if ( $tracked_branch{"remote"} ne "" ) {
      GitKttiUtils::git_remotePrune($tracked_branch{"remote"}, \$ret);

      ## Delete local branches not found on remote...
      foreach my $local_branch (GitKttiUtils::git_getLocalBranchesFilter('', \$ret)) {
        if ( scalar(GitKttiUtils::git_getRemoteBranchesFilter($tracked_branch{"remote"}, "$local_branch\$", \$ret)) == 0 ) {
          print "local branch '" . $local_branch . "' not found on remote.\n";
          GitKttiUtils::git_deleteLocalBranch($local_branch, \$ret);
        }
        else {
          print "local branch '" . $local_branch . "' found on remote. I will not delete it ^^\n";
        }
      }
    }
  }

  ## Local tags cleaning...
  if ( GitKttiUtils::isResponseYes("Do you want to clean your local tags?") &&
       GitKttiUtils::isResponseYes("! WARNING ! All local tags will be deleted. Are you sure to be sure?") ) {
    GitKttiUtils::git_cleanLocalTags(\$ret);
    GitKttiUtils::git_fetchTags(\$ret);
  }

  exit(0);
}

## arg : --tag
if ( $arg_tag ) {

  if($arg_tag !~ /^(EARTH|MOON|ISS|HALLEY|PB|MOBILE|FRONT)\-\d{1,6}$/) {
    die "ERR : tag must be like 'EARTH-XXX' or 'MOON-XXX' or 'ISS-XXX' or 'HALLEY-XXX' or 'PB-XXX' or 'MOBILE-XXX' or 'FRONT-XXX' (ex: EARTH-1234) !\n";
  }

  $suffix_branch = $arg_tag;
}
elsif ( $arg_name ) {

  if($arg_name !~ /^\w+$/) {
    die "ERR : invalid name !\n";
  }

  $suffix_branch = $arg_name;
}
else {
  $suffix_branch = strftime("%Y%m%d_%H%M%S", localtime);
}

## arg : --mode
if ( $arg_mode ) {

  if($arg_mode =~ /^(${\(MODE_HOTFIX)}|${\(MODE_FEATURE)}|${\(MODE_RELEASE)})$/) {
    $mode = $1;
  }
  else {
    die "ERR : mode must be 'hotfix' or 'feature' or 'release'!\n";
  }
}

## arg : --zeroprefix
if ( $arg_zeroprefix ) {
  $prefix_branch = "";
}
else {
  $prefix_branch = $mode . "_";
}

## Get current branch...
$current_branch = GitKttiUtils::git_getCurrentBranch(\$ret);

## mode : hotfix
if ( $mode eq MODE_HOTFIX ) {
  ## Check if we are on the right branch (master, hotfix_xxx, release_xxx)
  if($current_branch =~ /${\(REGEX_MASTER)}/ || $current_branch =~ /${\(REGEX_HOTFIX)}/  || $current_branch =~ /${\(REGEX_RELEASE)}/ ) {

    ## hotfix on hotfix ? strange but why not motherfucker
    if ( $current_branch =~ /${\(REGEX_HOTFIX)}/ ) {
      if ( !GitKttiUtils::isResponseYes("It seems that you wish to start a new hotfix from hotfix '" . $current_branch . "' #weirdo. Are you dumb ? If not, are you sure??") ) {
        die("END : aborted !\n");
      }
    }

    ## Hotfix name...
    $new_branch = $prefix_branch . $suffix_branch;
  }
  else {
    die "ERR : not on master/hotfix/release branch !\n";
  }
}
## mode : feature
elsif ( $mode eq MODE_FEATURE ) {
  ## Check if we are on develop/feature branch
if ( $current_branch =~ /${\(REGEX_DEVELOP)}/ || $current_branch =~ /${\(REGEX_FEATURE)}/ ) {

    ## feature on feature ? strange but why not motherfucker
    if ( $current_branch =~ /${\(REGEX_FEATURE)}/ ) {
      if ( !GitKttiUtils::isResponseYes("It seems that you wish to start a new feature from feature '" . $current_branch . "' #weirdo. Are you dumb ? If not, are you sure??") ) {
        die("END : aborted !\n");
      }
    }

    if ( !$arg_tag && !$arg_name ) {
      if ( !GitKttiUtils::isResponseYes("By default, you can use [" . $prefix_branch . "AAAAMMJJ_HHMISS]. Do you want to use it?") ) {
        $suffix_branch = "";
      }
    }

    if ( $suffix_branch eq "" ) {
      $suffix_branch = GitKttiUtils::getResponse("Please enter " . $mode . " branch name XXX (" . $prefix_branch . "XXX) :");
    }

    $new_branch = $prefix_branch . $suffix_branch;
  }
  else {
    die "ERR : not on develop branch !\n";
  }
}
## mode : release
elsif ( $mode eq MODE_RELEASE ) {
  ## Check if we are on develop branch
  if($current_branch =~ /${\(REGEX_DEVELOP)}/) {

    ## Get last tag from all branches
    $lasttag = GitKttiUtils::git_getLastTagFromAllBranches(\$ret);

    ## Tries to get automatically next name...
    if($lasttag =~ /^(\d+)\.(\d+)\.(\d+)$/) {
      $lasttag_maj   = $1;
      $lasttag_min   = $2;
      $lasttag_patch = $3;

      $new_branch = GitKttiUtils::getSelectResponse("Please select a release name (last tag is [$lasttag]) :",
          $mode . "_" . ($lasttag_maj+1) . "." . "0"              . "." . "0"                . "|next maj release",
          $mode . "_" . $lasttag_maj     . "." . ($lasttag_min+1) . "." . "0"                . "|next min release",
          $mode . "_" . $lasttag_maj     . "." . $lasttag_min     . "." . ($lasttag_patch+1) . "|next patch release",
          "|none of them ! (another name)");
    }
    else {
      print("Last tag is [$lasttag]. You should use next version for your release name ;)\n");
    }

    ## Use default datetime...
    if ( $new_branch eq "" ) {
      if ( GitKttiUtils::isResponseYes("By default, you can use [" . $prefix_branch . "AAAAMMJJ_HHMISS]. Do you want to use it?") ) {
        $new_branch = $prefix_branch . $suffix_branch;
      }
    }

    ## Or use custom name...
    if ( $new_branch eq "" ) {
      $suffix_branch = GitKttiUtils::getResponse("Please enter " . $mode . " branch name XXX (" . $prefix_branch . "XXX) :");
      $new_branch = $prefix_branch . $suffix_branch;
    }

    ## Last check...
    if ( $new_branch eq "" ) {
      die "ERR : branch name is empty !\n";
    }
  }
  else {
    die "ERR : not on develop branch !\n";
  }
}

print("\n");
print("mode            = [$mode]\n");
print("current branch  = [$current_branch]\n");
print("tracked[remote] = [" . $tracked_branch{"remote"} . "]\n");
print("tracked[branch] = [" . $tracked_branch{"branch"} . "]\n");
print("hotfix/feature  = [$new_branch]\n");
print("\n");

if ( GitKttiUtils::isResponseYes("Create $mode [$new_branch]?") ) {
  GitKttiUtils::launch("git checkout -b $new_branch", \$ret);
}
else {
  print("END : aborted !\n");
  exit(2);
}

if ( ($tracked_branch{"remote"} ne "") && (GitKttiUtils::isResponseYes("Push $mode [$new_branch] to remote [" . $tracked_branch{"remote"} . "]?")) ) {
  GitKttiUtils::launch("git push --set-upstream " . $tracked_branch{"remote"} . " " . $new_branch, \$ret);
}
