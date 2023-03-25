#! /usr/bin/perl
##############################################################################
## by ROBU
##############################################################################

use strict;
use warnings;
use File::Basename; ## For using 'basename'
use POSIX; ## For using 'strftime'
use GitKttiUtils;

GitKttiUtils::showVersion();

my $ret               = 99;
my $tagname           = "";
my $lasttag           = "";
my $lasttag_maj       = "";
my $lasttag_min       = "";
my $lasttag_patch     = "";
my $lasttag_number    = 0;
my $current_path      = getcwd();
my $current_dir       = basename($current_path);
my $current_branch    = GitKttiUtils::git_getCurrentBranch(\$ret);
my $current_repo_path = GitKttiUtils::git_getGitRootDirectory();
my $current_repo      = basename($current_repo_path);
my $version           = "";
my $version_maj       = "";
my $version_min       = "";
my $version_patch     = "";
my $version_number    = 0;

print("Current path      : [$current_path]\n");
print("Current dir       : [$current_dir]\n");
print("Current repo path : [$current_repo_path]\n");
print("Current repo      : [$current_repo]\n");

if($current_branch =~ /^master$/) {
  $lasttag = GitKttiUtils::git_getLastTagFromCurrentBranch(\$ret);
}
else {
  if ( !GitKttiUtils::isResponseYes("! WARNING ! You are not on master branch. Tagging should be made on master branch. Are you sure?") ||
       !GitKttiUtils::isResponseYes("! WARNING ! Are you sure to be sure?") ) {
    print("ERROR: You are not sure ! Aborted !\n");
    exit(2);
  }
}

if ( $tagname eq "" ) {
  $tagname = GitKttiUtils::getResponse("Last tag on this branch is [$lasttag]. Please enter tag value ('$lasttag' --> 'x.x.x') :");
}

print("Branch  : [$current_branch]\n");
if($lasttag ne "") { print("lasttag : [$lasttag]\n"); }
print("tagname : [$tagname]\n");

## Go tagging !
GitKttiUtils::git_tagBranch($current_branch, $tagname, $lasttag);
