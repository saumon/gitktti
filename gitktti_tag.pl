#! /usr/bin/perl
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

GitKttiUtils::printSection("Repository Information");

print(GitKttiUtils::BRIGHT_WHITE . "Current path:      " . GitKttiUtils::RESET . GitKttiUtils::CYAN . $current_path . GitKttiUtils::RESET . "\n");
print(GitKttiUtils::BRIGHT_WHITE . "Current directory: " . GitKttiUtils::RESET . GitKttiUtils::CYAN . $current_dir . GitKttiUtils::RESET . "\n");
print(GitKttiUtils::BRIGHT_WHITE . "Repository path:   " . GitKttiUtils::RESET . GitKttiUtils::CYAN . $current_repo_path . GitKttiUtils::RESET . "\n");
print(GitKttiUtils::BRIGHT_WHITE . "Repository name:   " . GitKttiUtils::RESET . GitKttiUtils::CYAN . $current_repo . GitKttiUtils::RESET . "\n");

if($current_branch =~ /^master$/) {
  $lasttag = GitKttiUtils::git_getLastTagFromCurrentBranch(\$ret);
}
else {
  if ( !GitKttiUtils::isResponseYes("! WARNING ! You are not on master branch. Tagging should be made on master branch. Are you sure?") ||
       !GitKttiUtils::isResponseYes("! WARNING ! Are you sure to be sure?") ) {
    GitKttiUtils::printError("You are not sure ! Aborted !");
    exit(2);
  }
}

if ( $tagname eq "" ) {
  $tagname = GitKttiUtils::getResponse("Last tag on this branch is " . GitKttiUtils::BOLD . $lasttag . GitKttiUtils::RESET . ". Please enter tag value ('" . $lasttag . "' --> 'x.x.x') :");
}

GitKttiUtils::printSubSection("Tagging Summary");

print(GitKttiUtils::BRIGHT_WHITE . "Branch:  " . GitKttiUtils::RESET);
if ($current_branch =~ /^master$/) {
  GitKttiUtils::printBranch($current_branch, "master");
} else {
  GitKttiUtils::printBranch($current_branch);
}
print("\n");

if($lasttag ne "") {
  print(GitKttiUtils::BRIGHT_WHITE . "Last tag: " . GitKttiUtils::RESET);
  GitKttiUtils::printTag($lasttag);
  print("\n");
}

print(GitKttiUtils::BRIGHT_WHITE . "New tag:  " . GitKttiUtils::RESET);
GitKttiUtils::printTag($tagname);
print("\n\n");

## Go tagging !
GitKttiUtils::git_tagBranch($current_branch, $tagname, $lasttag);
