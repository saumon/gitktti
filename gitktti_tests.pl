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

##############################################################################
########################### GLOBAL VARS ######################################
##############################################################################

my $ret = 99;

##############################################################################
########################### TEST FUNCTIONS ###################################
##############################################################################

sub test_getTrackedRemoteBranch(){
  print("test_getTrackedRemoteBranch()\n");

  my $current_branch = GitKttiUtils::git_getCurrentBranch(\$ret);
  my %tracked_branch = GitKttiUtils::git_getTrackedRemoteBranch(\$ret);

  print("test_getTrackedRemoteBranch : current_branch = [$current_branch]\n");
  print("test_getTrackedRemoteBranch : tracked_branch[remote] = [" . $tracked_branch{"remote"} . "]\n");
  print("test_getTrackedRemoteBranch : tracked_branch[branch] = [" . $tracked_branch{"branch"} . "]\n");
}

sub test_getLastTags(){
  print("\ntest_getLastTags()\n");

  my $lasttagfromall = GitKttiUtils::git_getLastTagFromAllBranches(\$ret);
  my $lasttagfromcur = GitKttiUtils::git_getLastTagFromCurrentBranch(\$ret);

  print("test_getLastTags : lasttagfromall = [$lasttagfromall]\n");
  print("test_getLastTags : lasttagfromcur = [$lasttagfromcur]\n");
}

sub test_getResponses(){
  my $rep = "";
  $rep = GitKttiUtils::isResponseYes("dormir ?"); print("test_getResponses : rep = [$rep]\n");
  $rep = GitKttiUtils::isResponseYes("vomir ?"); print("test_getResponses : rep = [$rep]\n");
  $rep = GitKttiUtils::getResponse("La forme ?"); print("test_getResponses : rep = [$rep]\n");
  $rep = GitKttiUtils::getResponse("La forme ?", "bof"); print("test_getResponses : rep = [$rep]\n");
}

sub test_launch(){
  my $command = GitKttiUtils::getResponse("command?");

  GitKttiUtils::launch($command, \$ret);
  print("test_launch : ret = [" . $ret . "]\n");
}

##############################################################################
########################### MAIN #############################################
##############################################################################

## test_getTrackedRemoteBranch();
## test_getLastTags();
## test_getResponses();
## test_launch();
