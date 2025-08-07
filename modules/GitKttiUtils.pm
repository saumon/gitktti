#! /usr/bin/perl
##############################################################################
## by ROBU
##############################################################################

package GitKttiUtils;
use strict;
use warnings;
use POSIX; ## For using 'strftime'
use constant GIT_KTTI_VERSION => "1.0.3";

sub showVersion {
  print("gitktti v". GIT_KTTI_VERSION ."\n\n");
}

##############################################################################
## Fonction launch
## Permet d executer une commande shell. Prend en entree la commande
## a executer et retourne une liste contenant le resultat d execution de la
## fonction.
##############################################################################
sub launch {
  my $command   = $_[0];
  my $ref_state = $_[1];
  my @out = ();

  $$ref_state = 99;

  if ( length($command) == 0 ) {
    print("launch : command is empty !\n");
    return @out;
  }

  print("--------------------------------------------------------------------------------\n");
  print("-- Execute [$command]\n");
  open (CMD, "$command |") or die "launch : ERROR !";
  while(my $ligne = <CMD>) {
    print($ligne);
    chomp($ligne);
    push(@out, $ligne);
  }
  close(CMD);

  ## Get output state
  $$ref_state = $? >> 8;

  if ( $$ref_state ne 0 ) {
    print("\n\$? --> " . $$ref_state . "\n");
  }

  print("--------------------------------------------------------------------------------\n");
  print("\n");
  return @out;
}

sub isResponseYes {
  my $question = $_[0];
  my $rep = "";

  do
  {
    $rep = lc(getResponse($question . " (y/n)"));
  }
  while ( $rep !~ /^y$/ && $rep !~ /^n$/ );

  if ( $rep eq 'y' ) {
    return 1;
  }
  else {
    return 0;
  }
}

sub getResponse {
  my $question = $_[0];
  my $default = $_[1];
  my $rep = "";

  print("\n");
  print("--------------------------------------------------------------------------------\n");
  print("$question");
  if ( defined($default) && length($default) > 0 ) {
    print(" (" . $default . ")");
  }
  print("\n");

  $rep = <STDIN>;
  print("--------------------------------------------------------------------------------\n");
  print("\n");

  chomp($rep);

  if ( defined($default) && length($default) > 0 && length($rep) == 0 ) {
    $rep = $default;
  }

  return($rep);
}

sub getSelectResponse {

  my $rep         = "";
  my $i_rep       = 0;
  my $nb_elts     = scalar @_;
  my $max_len_rep = 0;

  if ( $nb_elts <= 1 ) {
    die("ERROR: getSelectResponse, missing args !");
  }

  my $question = $_[0];

  print("\n");
  print("--------------------------------------------------------------------------------\n");
  print("$question\n");

  for(my $i = 1; $i < $nb_elts; $i++) {
    my @list = split(/\|/, $_[$i]);
    my $len = length($list[0]);
    if ( $len > $max_len_rep ) { $max_len_rep = $len };
  }

  for(my $i = 1; $i < $nb_elts; $i++) {
    my @list = split(/\|/, $_[$i]);
    my $line = " " . LPad($i, 3, ' ') . ") --> " . RPad($list[0], $max_len_rep, ' ');

    if ( scalar @list > 1 ) {
      $line .= " (" . $list[1] . ")";
    }

    print($line . "\n");
  }

  do {
    print("Your choice : ");
    $i_rep = <STDIN>;
  }
  while ( $i_rep !~ /^\d+$/ || ($i_rep < 1) || ($i_rep > ($nb_elts - 1)) );

  if ( ($i_rep >= 1) && ($i_rep < $nb_elts) ) {
    my @list = split(/\|/, $_[$i_rep]);
    $rep = $list[0];
    print("You have chosen --> [$rep]\n");
  }

  print("--------------------------------------------------------------------------------\n");
  print("\n");

  chomp($rep);

  return($rep);
}

#---------------------------------------------------------------------
# LPad
#---------------------------------------------------------------------
# Pads a string on the left end to a specified length with a specified
# character and returns the result.  Default pad char is space.
#---------------------------------------------------------------------

sub LPad {
  my ($str, $len, $chr) = @_;
  $chr = " " unless (defined($chr));
  return substr(($chr x $len) . $str, -1 * $len, $len);
} # LPad

#---------------------------------------------------------------------
# RPad
#---------------------------------------------------------------------
# Pads a string on the right end to a specified length with a specified
# character and returns the result.  Default pad char is space.
#---------------------------------------------------------------------

sub RPad {
  my ($str, $len, $chr) = @_;
  $chr = " " unless (defined($chr));
  return substr($str . ($chr x $len), 0, $len);
} # RPad

sub directoryExists {
  my $path      = $_[0];
  my $directory = $_[1];
  my $found     = 0;

  opendir(my $dh, $path) or die("ERROR: directoryExists, bad path given !");

  while ( !$found && (my $file = readdir($dh)) ) {
    if ( -d "$path/$file" && $file =~ /^$directory$/ ) {
      $found = 1;
    }
    }
  closedir($dh);

  return $found;
}

sub git_getTrackedRemoteBranch {
  my $ref_ret = $_[0];
  my %index_remotebranch = ();

  $index_remotebranch{"remote"} = "";
  $index_remotebranch{"branch"} = "";

  my @remotebranch = launch('git rev-parse --abbrev-ref --symbolic-full-name @{u}', $ref_ret);

  if(@remotebranch >= 1 && $remotebranch[0] =~ /^(.+)\/(.+)$/) {
    $index_remotebranch{"remote"} = $1;
    $index_remotebranch{"branch"} = $2;
  }

  return %index_remotebranch
}

sub git_getGitRootDirectory {

  my $ret       = 99;
  my $directory = "";

  $directory = (launch('git rev-parse --show-toplevel', \$ret))[0];

  ## Exit if checkout fails
  if ( $ret ne 0 ) {
    print("ERROR: getGitRootDirectory failed ! Aborted !\n");
    exit(2);
  }

  return $directory;
}

sub git_isRepoClean {
  my $ret   = 99;
  my $clean = 1;

  my @files = launch('git status --porcelain', \$ret);

  if(@files > 0) {
    $clean = 0;
  }

  return $clean;
}

sub trim {
  my $s = shift;
  $s =~ s/^\s+|\s+$//g;
  return $s
}

sub super_scp {
  my $rep_src    = $_[0];
  my $rep_dest   = $_[1];
  my $srv_user   = $_[2];
  my $srv_ip     = $_[3];
  my $ret        = 99;

  print("SRC  : $rep_src\n");
  print("DEST : $rep_dest\n");
  print("USER : $srv_user\n");
  print("HOST : $srv_ip\n");

  if ( isResponseYes("Synchronize [SRC] to [DEST] ? (with 'scp')") ) {

    # Without redirecting to /dev/tty I get no output...
    launch("scp -r $rep_src $srv_user\@$srv_ip:$rep_dest >/dev/tty", \$ret);

    ## Exit if scp fails
    if ( $ret ne 0 ) {
      print("ERROR: scp failed ! Aborted !\n");
      exit(2);
    }
  }
}

sub super_rsync_ssh {
  my $rep_src    = $_[0];
  my $rep_dest   = $_[1];
  my $srv_user   = $_[2];
  my $srv_ip     = $_[3];
  my $use_delete = $_[4];
  my $opt_delete = "";
  my $ret        = 99;

  print("SRC  : $rep_src\n");
  print("DEST : $rep_dest\n");
  print("USER : $srv_user\n");
  print("HOST : $srv_ip\n");

  if ( isResponseYes("Synchronize [SRC] to [DEST] ? (with 'rsync')") ) {

    ## Warning: using [--delete] can be dangerous !!!
    if ( $use_delete && isResponseYes("Use option [--delete] ? (WARNING: can be dangerous) !") ) {
      $opt_delete = "--delete";
    }

    launch("rsync -e ssh -avz --progress $opt_delete $rep_src $srv_user\@$srv_ip:$rep_dest", \$ret);

    ## Exit if rsync fails
    if ( $ret ne 0 ) {
      print("ERROR: rsync failed ! Aborted !\n");
      exit(2);
    }
  }
}

sub super_rsync_ssh_with_exclude {
  my $rep_src          = $_[0];
  my $rep_dest         = $_[1];
  my $srv_user         = $_[2];
  my $srv_ip           = $_[3];
  my $use_delete       = $_[4];
  my $use_fakesuper    = $_[5];
  my $skip_confirm     = $_[6];
  my $ref_list_exclude = $_[7];
  my $opt_delete       = "";
  my $opt_fakesuper    = "";
  my $opt_exclude      = "";
  my $ret              = 99;
  my $go               = 0;

  print("SRC  : $rep_src\n");
  print("DEST : $rep_dest\n");

  foreach my $exclude (@{$ref_list_exclude}) {
    print("EXCL : $exclude\n");

    $opt_exclude .= "--exclude '$exclude' ";
  }

  if ( $use_fakesuper ) {
    $opt_fakesuper = "--rsync-path='rsync --fake-super' ";
  }

  print("USER : $srv_user\n");
  print("HOST : $srv_ip\n");

  if ( $skip_confirm ) {
    $go = 1;
  }
  else {
    $go = isResponseYes("Synchronize [SRC] to [DEST] ? (with 'rsync')");
  }

  if ( $go ) {

    ## Warning: using [--delete] can be dangerous !!!
    if ( $use_delete && isResponseYes("Use option [--delete] ? (WARNING: can be dangerous) !") ) {
      $opt_delete = "--delete ";
    }

    ## Launch rsync command
    launch("rsync -avzhe ssh " . $opt_fakesuper . $opt_delete . $opt_exclude . "$rep_src $srv_user\@$srv_ip:$rep_dest", \$ret);

    # Exit if rsync fails
    if ( $ret ne 0 ) {
      print("ERROR: rsync failed ! Aborted !\n");
      exit(2);
    }
  }
}

sub git_checkoutBranch {
  my $arg_branch = $_[0];
  my $ret        = 99;

  if (isResponseYes("Checkout branch [$arg_branch]?") ) {

    launch("git checkout $arg_branch", \$ret);

    ## Exit if checkout fails
    if ( $ret ne 0 ) {
      print("ERROR: checkout failed ! Aborted !\n");
      exit(2);
    }
  }
}

sub git_checkoutBranchNoConfirm {
  my $arg_branch = $_[0];
  my $ret        = 99;

  launch("git checkout $arg_branch", \$ret);

  ## Exit if checkout fails
  if ( $ret ne 0 ) {
    print("ERROR: checkout failed ! Aborted !\n");
    exit(2);
  }
}

sub git_deleteLocalBranch {
  my $arg_branch = $_[0];
  my $ret        = 99;
  my $done       = 0;

  if (isResponseYes("Delete local branch [$arg_branch]?") ) {

    ## Delete current branch
    launch("git branch -D $arg_branch", \$ret);

    ## Exit if command fails
    if ( $ret ne 0 ) {
      print("ERROR: delete failed ! Aborted !\n");
      exit(2);
    }

    $done = 1;
  }

  return $done;
}

sub git_getLocalBranchesFilter {
  return launch("git branch | awk -F ' +' '! /\\(no branch\\)/ {print \$2}' | grep -E \"$_[0]\"", $_[1]);
}

sub git_getRemoteBranchesFilter {

  my $arg_remote = $_[0];
  my $arg_filter = $_[1];
  my $ref_ret    = $_[2];
  my @branches   = ();

  if ( $arg_remote ne "" ) {
    push(@branches, launch("git branch --remote | awk -F ' +' '! /\\(no branch\\)/ {print \$2}' | grep -E \"$arg_filter\"", $ref_ret));
  }

  return @branches;
}

sub git_getAllBranchesFilter {

  my $arg_remote = $_[0];
  my $arg_filter = $_[1];
  my $ref_ret    = $_[2];
  my @branches   = ();

  push(@branches, git_getRemoteBranchesFilter($arg_remote, $arg_filter, $ref_ret));
  push(@branches, git_getLocalBranchesFilter($arg_filter, $ref_ret));

  return @branches;
}

sub git_getCurrentBranch {
  my $ref_ret = $_[0];
  return (launch('git rev-parse --abbrev-ref HEAD', $ref_ret))[0];
}

sub git_fetch {
  my $ref_ret = $_[0];
  launch("git fetch", $ref_ret);
}

sub git_getLastTagFromAllBranches {
  my $ref_ret = $_[0];
  my @out = launch('git describe --tags $(git rev-list --tags --max-count=1)', $ref_ret);

  if(@out > 0) {
    return $out[0];
  }
  else {
    return "";
  }
}

sub git_getLastTagFromCurrentBranch {
  my $ref_ret = $_[0];
  my @out = launch('git describe --abbrev=0 --tags', $ref_ret);

  if(@out > 0) {
    return $out[0];
  }
  else {
    return "";
  }
}

sub git_cleanLocalTags {
  my $ref_ret = $_[0];
  return (launch('git tag -l | xargs git tag -d', $ref_ret))[0];
}

sub git_fetchTags {
  my $ref_ret = $_[0];
  return (launch('git fetch --tags', $ref_ret))[0];
}

sub git_fetchPrune {
  my $ref_ret = $_[0];
  return (launch('git fetch --all --prune', $ref_ret))[0];
}

sub git_remotePrune {
  my $arg_remote = $_[0];
  my $ref_ret    = $_[1];
  return (launch("git remote prune $arg_remote", $ref_ret))[0];
}

## ATTENTION :
##  - ne marche pas a 100% (va a l'encontre de la logique git)
##  - des commits avec des [ ] cassent la fonction
##    Exemple : "[G401-439] Page not found"
## warning, this one is hard like chuck norris's dick
sub git_getParentBranch {
  my $ref_ret = $_[0];
  ## git show-branch -a | grep '\*' | grep -v `git rev-parse --abbrev-ref HEAD` | head -n1 | sed 's/.*\[\(.*\)\].*/\1/' | sed 's/[\^~].*//'
  #return (launch("git show-branch -a | grep '\\*' | grep -v `git rev-parse --abbrev-ref HEAD` | head -n1 | sed 's/.*\\[\\(.*\\)\\].*/\\1/' | sed 's/[\\^~].*//'", $ref_ret))[0];

  ## git show-branch | sed "s/].*//" | grep "\*" | grep -v "$(git rev-parse --abbrev-ref HEAD)" | head -n1 | sed "s/^.*\[//"
  #return (launch("git show-branch | sed \"s/].*//\" | grep \"\\*\" | grep -v \"$(git rev-parse --abbrev-ref HEAD)\" | head -n1 | sed \"s/^.*\\[//\"", $ref_ret))[0];

  ## git show-branch | grep '*' | grep -v "$(git rev-parse --abbrev-ref HEAD)" | head -n1 | sed 's/.*\[\(.*\)\].*/\1/' | sed 's/[\^~].*//'
  return (launch("git show-branch | grep '*' | grep -v \"\$(git rev-parse --abbrev-ref HEAD)\" | head -n1 | sed 's/.*\\[\\(.*\\)\\].*/\\1/' | sed 's/[\\^~].*//'", $ref_ret))[0];
}

sub git_tagBranch {
  my $branch  = $_[0];
  my $tagname = $_[1];
  my $lasttag = $_[2];

  my $ret          = 99;
  my $tagging_done = 0;
  my $question     = "Create tag [$tagname] on branch '$branch'";

  if ( $tagname eq "" ) {
    print("ERROR: git_tagBranch, no tagname provided !\n");
    exit(2);
  }

  if ( $lasttag ne "" ) {
    $question .= " (old tag is [$lasttag])";
  }

  ## Check current branch name
  if(git_getCurrentBranch(\$ret) !~ /^$branch$/) {
    print("ERROR: git_tagBranch, bad branch ! (you should be on branch '$branch')\n");
    exit(2);
  }

  $question .= "?";

  if (isResponseYes($question) ) {
    ## Tags current branch...
    launch("git tag -a $tagname -m 'version $tagname'", \$ret);

    ## Exit if tagging fails
    if ( $ret ne 0 ) {
      print("ERROR: tagging failed ! Aborted !\n");
      exit(2);
    }
    else {
      print("Tag [$tagname] created !\n");
      $tagging_done = 1;
    }

    ## Get tracked remote branch...
    my %tracked_branch = git_getTrackedRemoteBranch(\$ret);

    if ( $tracked_branch{"remote"} ne "" &&  $tracked_branch{"branch"} ne "" ) {
      if (isResponseYes("Push tag [$tagname]?") ) {
        ## Pushes tag to remote...
        launch("git push --follow-tags", \$ret);

        ## Exit if checkout fails
        if ( $ret ne 0 ) {
          print("ERROR: push failed ! Aborted !\n");
          exit(2);
        }
      }
    }
    else {
      print("No remote, no push, no chocolate !\n");
    }
  }
  else {
    print("Tagging aborted !\n");
  }

  return $tagging_done;
}

sub git_pullCurrentBranch {
  my $arg_remote                 = $_[0];
  my $arg_tracking_remote_branch = $_[1];

  my $ret = 99;

  if ( $arg_remote ne "" && $arg_tracking_remote_branch ne "" ) {

    ## Pulls branch...
    launch("git pull", \$ret);

    ## Exit if pull fails
    if ( $ret ne 0 ) {
      print("ERROR: pull failed ! Aborted !\n");
      exit(2);
    }
  }
  # else {
  #   print("pullCurrentBranch : no remote, no pull, no chocolate...\n");
  # }
}

sub git_deleteCurrentBranch {
  my $arg_current_branch         = $_[0];
  my $arg_remote                 = $_[1];
  my $arg_tracking_remote_branch = $_[2];

  my $ret = 99;

  if (isResponseYes("Delete branch [$arg_current_branch]?") ) {

    ## Delete current branch
    launch("git branch -d $arg_current_branch", \$ret);

    ## Delete remote branch
    if ( $arg_remote ne "" && $arg_tracking_remote_branch ne "" ) {
      if (isResponseYes("Delete tracking remote branch [" . $arg_remote . "/" . $arg_tracking_remote_branch . "]?") ) {
        launch("git push " . $arg_remote . " --delete " . $arg_tracking_remote_branch, \$ret);
      }
    }
  }
}

sub git_mergeIntoBranch {
  my $arg_branch_into     = $_[0];
  my $arg_branch_to_merge = $_[1];

  my $ret        = 99;
  my $merge_done = 0;

  if (isResponseYes("Merge branch '$arg_branch_to_merge' into '$arg_branch_into'?") ) {
    launch("git checkout $arg_branch_into", \$ret);

    ## Exit if checkout fails
    if ( $ret ne 0 ) {
      print("ERROR: checkout failed ! Aborted !\n");
      exit(2);
    }

    ## Get tracked remote branch...
    my %tracked_branch_into = git_getTrackedRemoteBranch(\$ret);

    ## Pull it
    git_pullCurrentBranch($tracked_branch_into{"remote"}, $tracked_branch_into{"branch"});

    launch("git merge --no-ff $arg_branch_to_merge", \$ret);

    ## Exit if merge fails
    if ( $ret ne 0 ) {
      print("ERROR: merge failed ! Aborted !\n");
      exit(2);
    }
    else {
      $merge_done = 1;
    }

    if ( $tracked_branch_into{"remote"} ne "" &&  $tracked_branch_into{"branch"} ne "" ) {
      if (isResponseYes("Push '$arg_branch_into'?") ) {
        launch("git push", \$ret);

        ## Exit if push fails
        if ( $ret ne 0 ) {
          print("ERROR: push failed ! Aborted !\n");
          exit(2);
        }
      }
    }
  }

  return $merge_done;
}

sub git_duplicateRepository {
  my $old_repository = $_[0];
  my $new_repository = $_[1];

  my $ret       = 99;
  my $temp_repo = "";

  if ( $old_repository eq "" ) {
    print("ERROR: old_repository is empty !\n");
    exit(2);
  }

  if ( $new_repository eq "" ) {
    print("ERROR: new_repository is empty !\n");
    exit(2);
  }

  $temp_repo = "TEMPREPO_" . strftime("%Y%m%d_%H%M%S", localtime);

  ## Step 1: clone old repository
  launch("git clone --bare $old_repository $temp_repo", \$ret);

  if ( $ret ne 0 ) {
    print("ERROR: clone failed ! Aborted !\n");
    exit(2);
  }

  ### Step 2: push to new repository
  chdir($temp_repo);
  print("now here : " . getcwd() . "\n");

  launch("git push --mirror $new_repository", \$ret);

  if ( $ret ne 0 ) {
    print("ERROR: push failed ! Aborted !\n");
    exit(2);
  }

  ## Step 3: clean temp repositoy
  chdir("..");
  print("now here : " . getcwd() . "\n");

  launch("rm -rf $temp_repo", \$ret);

  if ( $ret ne 0 ) {
    print("ERROR: cd failed ! Aborted !\n");
    exit(2);
  }

  print("Repository successfuly duplicated !\n");
  print("From [$old_repository]\n");
  print("To   [$new_repository]\n");
}

1;
