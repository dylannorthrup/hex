#!/usr/bin/perl
#
# Take draft data (in JSON format) and update the probabilities that a card will be chosen

use strict;
use JSON::PP qw(decode_json);
use DBI;
use File::Copy;
#use Data::Dumper;

# Variables
my $pack_cards = 17;
my %pick_locs;
my $log_file;
my @tournaments;
my $ingest_dir = "/home/docxstudios/web/hex/code/draft_logs/ingested";

# Make sure we have an argument
if (defined $ARGV[0]) {
  $log_file = $ARGV[0];
} else {
  die "No log file specified on command line";
}


# Something to print out the probabilities cards will wheel.
sub print_wheel_probs {
  my $foo = shift @_;
  # Go through each spot. If it has a value, print it. If not, print '0'
  my $all_cards = $foo->{'0'};
  my $cards_left = $all_cards;
  for my $p (1..17) {
    if ($p > 8) {
      my $prob = int(($cards_left / $all_cards) * 100);
      print "$p - $prob%, ";
    }
    # If this is defined, subtract it from the cards_left
    if (defined $foo->{$p}){
      $cards_left -= $foo->{$p};
      # If we don't have any more cards, return
      if ($cards_left <= 0) {
        print "\n"; 
        return;
      }
    }
  }
  print "\n";
}

# Get string representation of the pick locations for the pack
sub stringify_pick_locs {
  my $foo = shift @_;
  my $retvar = "";
  # Go through each spot. If it has a value, print it. If not, print '0'
  for my $p (0..17) {
    if (defined $foo->{$p}){
      $retvar .= "$foo->{$p}";
    } else {
      $retvar .= '0';
    }
    # We want ':' between each value, but not after the last (and 17th) pick
    $retvar .= ':' if $p < 17;
  }
#  print "\n";
}

# Print out the pick locations for the pack
sub print_pick_locs {
  my $foo = shift @_;
  my $pl = "";
#  print ">>$pl<<\n";
  # Go through each spot. If it has a value, print it. If not, print '0'
  for my $p (0..17) {
    if (defined $foo->{$p}){
      $pl .= "$foo->{$p}";
    } else {
      $pl .= '0';
    }
    # We want ':' between each value, but not after the last (and 17th) pick
    $pl .= ':' if $p < 17;
  }
  return $pl;
#  print ">>$pl<<\n";
}

# Get database password
sub get_db_pw {
  my $pw_file = '/home/docxstudios/hex_tcg.pw';
  open(PW, $pw_file) || die "Cannot open $pw_file for reading: $!\n";
  my $pw = <PW>;
  close PW;
  chomp $pw;
  return $pw;
}

# Open up handle to DB
sub get_dbh {
  my $pw = get_db_pw;
  my $dbh = DBI->connect("DBI:mysql:database=hex_tcg;host=mysql.doc-x.net", "hex_tcg", $pw,
                          {'RaiseError' => 1});
  return $dbh;
}

# Merge old and new picks
sub merge_picks {
  my $op = shift @_;
  my $np = shift @_;
  my $mp = "";
  my @o = split /:/, $op;
  my @n = split /:/, $np;
  my @m = ();
  for my $i (0..$#n) {
    $m[$i] = $o[$i] + $n[$i];
#    print "$m[$i] = $o[$i] + $n[$i]\n";
  }
  my $next_to_last_index = $#m - 1;
  for my $i (0..$next_to_last_index) {
    $mp .= $m[$i] . ":";
  }
  $mp .= $m[$#m];
#  print "merged: $mp\n";
  return $mp;
}

# Get the picks for a particular UUID
sub update_uuid_picks {
  my $dbh = shift @_;
  my $uuid = shift @_;
  my $new_picks = shift @_;
  my $query = "SELECT picks FROM draft_data WHERE uuid LIKE '$uuid'";
  my $sth = $dbh->prepare($query);
  $sth->execute();
  # Should only be 1 row
  my $ref = $sth->fetchrow_hashref();
  my $picks = $ref->{'picks'};
  $sth->finish();
  # If this is the case, we don't have any data. Go ahead and insert what we have
  if ($picks =~ /^$/) {
    $query = "INSERT INTO draft_data (uuid, picks) values ('$uuid', '$new_picks')";
#    print "No picks for $uuid. Query to do straight insert.\n$query\n";
  } else {
#    print "Prior picks exist for $uuid. Doing merge.\n";
#    print "old picks: $picks\nnew picks: $new_picks\n";
    my $merged_picks = merge_picks($picks, $new_picks);
    $query = "UPDATE draft_data SET picks = '$merged_picks' WHERE uuid like '$uuid'";
#    print "Merged picks: $merged_picks\n";
  }
  $dbh->do($query);
}

my $dbh = get_dbh();
#update_uuid_picks($dbh, "123", "1:2:3:4:5:6:7:8:9:10:11:12:13:14:15:16:17");
#exit;

# Open the log file up for reading
if ($log_file =~ /\.gz$/) {
#  print "Doing gunzip on log file $log_file\n";
  open(DLOG, "gunzip -dc $log_file |") || die "Cannot gunzip $log_file for reading: $!\n";
} else {
#  print "Opening log file $log_file\n";

  open(DLOG, $log_file) || die "Can't open $log_file for reading: $!\n";
}

# Read in file and process JSON
my $json_string = "";
while(my $line = <DLOG>) {
  # Test if this is a blank space.  The format of the file is three blank lines separates each tournament
  if ($line =~ /^$/) {
    next if ($json_string =~ /^$/);
    next if ($json_string eq "");
    # Now we should have a JSON string. Let's decode it and throw it on the tournaments pile
    my $decoded = decode_json $json_string;
    push @tournaments, $decoded;
    # Now, reset the string
    $json_string = "";
  } else {
    # Ignore actual tournament data (which we're not interested in for this application)
    if ($line =~ /^.*{ "PlayerOne" :/) {
      if ($line =~ /,$/) {
        $line = "\"\", \n";
      } else {
        $line = "\"\" \n";
      }
    }
    # Do some line trimming here since we just care about the Pick, not the Pack
    if ($line =~ /^\s+{ "Pack" :/) {
#      $line =~ s/"Pack" : \[.*\], "Pick"/"Pick"/;
      $line =~ s/"........-....-....-....-............", /"", /g;
      $line =~ s/"........-....-....-....-............" \]/"" ] /g;
    }
    $json_string .= $line;
  }
}

# Go through each tournament and grab out the picks from the players
foreach my $t (@tournaments) {
  my $draft = $t->{'Draft'};
  
  foreach my $d (@$draft) {
    my $picks = $d->{'Picks'}; 
    foreach my $p (@$picks) { 
      my $cards = $p->{'Pack'};
      my $pack = $pack_cards - $#$cards;
      $pick_locs{$p->{'Pick'}}{$pack} += 1;
      # Do this to keep track of total numbers of cards.
      $pick_locs{$p->{'Pick'}}{0} += 1;
    }
  }
}
#print Dumper(%pick_locs);
#pry();
foreach my $u (keys %pick_locs) {
#  print "$u:";
  my $foo = $pick_locs{$u};
  my $pl = print_pick_locs($foo);
  update_uuid_picks($dbh, $u, $pl);
#  print "PL: $pl\n";
#  print_wheel_probs($foo);
}

# Now that we've processed the file, move it to the 'ingested' folder
my $base_log_file = $log_file;
$base_log_file =~ s#.*/([^/]+)#$1#;
my $target = "$ingest_dir/$base_log_file";
move($log_file, $target) || die "Move of $log_file to $target failed: $!\n";
