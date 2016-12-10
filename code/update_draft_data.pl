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
my $tourn_time;
my $start_time = time();
my $now_time;
my $prev_time = $start_time;

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
}

# Print out the pick locations for the pack
sub print_pick_locs {
  my $foo = shift @_;
  my $pl = "";
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
  my $wdbh = shift @_;
  my $uuid = shift @_;
  my $new_picks = shift @_;
  my $query = "SELECT picks FROM draft_data WHERE uuid LIKE '$uuid'";
  my $sth = $wdbh->prepare($query);
  $sth->execute();
  # Should only be 1 row
  my $ref = $sth->fetchrow_hashref();
  my $picks = $ref->{'picks'};
  $sth->finish();
  # If this is the case, we don't have any data. Go ahead and insert what we have
  if ($picks =~ /^$/) {
    $query = "INSERT INTO draft_data (uuid, picks) values ('$uuid', '$new_picks')";
  } else {
    my $merged_picks = merge_picks($picks, $new_picks);
    $query = "UPDATE draft_data SET picks = '$merged_picks' WHERE uuid like '$uuid'";
  }
  $wdbh->do($query);
}

sub mark_tournament_processed {
  my $wdbh = shift @_;
  #my $query = "UPDATE tournament_data SET processed = true WHERE td LIKE '%\"TournamentType\" : \"Draft\",%' AND insert_time LIKE '$tourn_time'";
  my $query = "UPDATE tournament_data SET processed = true WHERE insert_time LIKE '$tourn_time'";
  my $sth = $wdbh->prepare($query);
  $sth->execute();
  $sth->finish();
}

sub print_timing_message {
  my $msg = shift @_;
  $now_time = time();
  my $diff = $now_time - $prev_time;
  print "$msg - $diff secs\n";
  $prev_time = $now_time;
}

sub get_tournament_data {
  my $rdbh = shift @_;
  my $query = "SELECT td, insert_time FROM tournament_data WHERE td LIKE '%    \"Draft\" :%' AND processed IS NULL ORDER BY insert_time ASC";
  my $sth = $rdbh->prepare($query);
  $sth->execute();
  # Should only be 1 row
  while(defined(my $ref = $sth->fetchrow_hashref())) {
    my $td = $ref->{'td'};
    $tourn_time = $ref->{'insert_time'};
    process_tournament($td);
    #return $td
  } 
  print "No more unprocessed draft tournaments. Exiting\n";
  $sth->finish();
  exit;
}

# Moving stuff into sub so I can loop over everything
sub process_tournament {
  my $json_string = shift @_;
  my $ndbh = get_dbh();
  print_timing_message("Massaging");
  $json_string =~ s/"Games" :.*/"_foo" : "_bar"\n}\n/sm;
  # Adding because, for some reason, we're getting 2x double quotes for some things
  $json_string =~ s/:\s+""/: "/smg;
  $json_string =~ s/"",/",/smg;
  print_timing_message("Decoding");
  my $t;
  # Adding this in so we can catch JSON parse errors and investigate them instead of simply dying
  eval {
    $t = decode_json $json_string;
    1;
  } or do {
    # If we did run into a problem, show the problematic string and GTFO
    print "Problem decoding the following 'json' string:\n";
    print $json_string;
    return;
  };
  
  # Go through the tournament and grab out the player picks
  print_timing_message("Grabbing picks");
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
  
  $| = 1;
  # Do the updating of rows in database
  print_timing_message("Updating UUID picks in database");
  print "updating rows: ";
  foreach my $u (keys %pick_locs) {
    print ".";
    my $foo = $pick_locs{$u};
    my $pl = print_pick_locs($foo);
    update_uuid_picks($ndbh, $u, $pl);
    print "PL: $pl\n";
    print_wheel_probs($foo);
  }
  print "\n";
  
  print_timing_message("Marking tournament at $tourn_time as processed");
  mark_tournament_processed($ndbh);
}

#### END SUB DEFINITIONS

my $wdbh = get_dbh();
my $rdbh = get_dbh();

print "=== Beginning draft data update run\n";
print_timing_message("Getting tournament_data");
# Select data from tournament_data and process it
get_tournament_data($rdbh);
#print "$json_string";
print_timing_message("Exiting");
my $run_time = $now_time - $start_time;
print "Total run time: $run_time secs\n";
