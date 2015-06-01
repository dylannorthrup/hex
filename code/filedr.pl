#!/usr/bin/perl
#
# Code is shared under Creative Commons Attribution-NonCommercial-Sharalike 4.0 Unported License
# More details at http://creativecommons.org/licenses/by-nc-sa/4.0/
# Code originally written by Dylan Northrup

use Fcntl qw(:flock);

%card_info  = {};
$api_file = 'api.data';
$api_file_mtime = 0;  # Set this to epoch so it'll read it first time through
$sleep_interval = 1;  # Number of seconds to wait to check for changes in $api_file
$game_timer = 0;      # A timer to count the length of games
$pack_plat_total = 0; # A counter to keep track of card value so far in plat
$booster_value = 0;   # Something we used to keep track of the value of boosters
$current_profit = 0;  # Keep track of total profit/loss for session
$collection_file = 'collection.out';
$collection_pending = 0;
$collection_info = "";
$price_file = 'price_and_count_data.out';
$best_gold  = "";
$best_plat  = "";
$fewest     = "";
$DEBUG = 0;

# Auto-flush on IO
$| = 1;

# Debugging print statement
sub pdebug {
  return unless $DEBUG;
  print STDERR "DEBUG: @_\n";
}

# So, we want to write out our collection file IF we have some collection data to print
$SIG{'ALRM'} = sub {
  # Set up next signal for 20 seconds from now
  alarm 20;

  # Return now unless we have collection info pending
  return unless $collection_pending;
  # Reset '$collection_pending'
  $collection_pending = 0;
  open(COLLECTION, ">$collection_file") || die "Can't write to collection file $collection_file: $!\n";
  print "\nWriting out collection data to $collection_file\n";
  print COLLECTION $collection_info;
  close COLLECTION;
};

# Some file lock methods
sub file_lock {
  my ($fh) = @_;
  flock($fh, LOCK_EX) or die "Can't lock file: $!\n";
}

sub file_unlock {
  my ($fh) = @_;
  flock($fh, LOCK_UN) or die "Can't unlock file: $!\n";
}

# Comparison functions for determining best plat, gold and fewest cards
sub fewest_cards {
  $first = shift @_;
  $second = shift @_;
  if (! defined $second || $second eq '') { return $first; }
  $field = 'count';
  if(int($card_info{$first}{$field}) < int($card_info{$second}{$field})){ return $first; }
  return $second;
}

sub best_plat {
  $first = shift @_; $second = shift @_; $field = 'plat';
  return which_is_larger($first, $second, $field);
}

sub best_gold {
  $first = shift @_; $second = shift @_; $field = 'gold';
  return which_is_larger($first, $second, $field);
}

sub which_is_larger {
  $first = shift @_; $second = shift @_; $field = shift @_;
  if(int($card_info{$first}{$field}) > int($card_info{$second}{$field})){ return $first; }
  return $second;
}

# Strip out bits from line and make it pipe delimited
sub sanitize_line {
  my $pat = shift @_;
  my $line = shift @_;
  chomp $line;
  $line =~ s/^.+$pattern\\?",\\?"[^"]+",\[\\?"//;
  #$line =~ s/^.+$pattern\\?",\\?"[^"]+//;
  $line =~ s/[\\"\]]+$//;
  $line =~ s/\\?",\\?"/|/g;
  $line =~ s/,//g;
  return $line;
}

# Something to construct a string including card name, quantity and value in plat and gold
sub get_card_info {
  $name = shift @_;
  $info = "'$name' [Qty: $card_info{$name}{'count'}] - $card_info{$name}{'plat'}p and $card_info{$name}{'gold'}g\n";
  return $info;
}

# This gets run to read in the data from the api file
sub read_api_file {
  # The string we'll be returning
  my $ret_val = "";
  # Go into a loop watching for modifications of the file
  while(1) {
    # Get last modificaiton time of file
    my $current_api_file_mtime = (stat($api_file))[9];  
    # If the modification time is greater than when we last looked at the file, lets read it in
    if ($api_file_mtime < $current_api_file_mtime) {
      # First thing we do, set the api_file_mtime to the current value to prevent infinite looping :-)
      $api_file_mtime = $current_api_file_mtime;
      # The data is only printed there a single line at a time, so we open, grab that line and close
      open(my $api, $api_file) || die "Can't open '$api_file' for reading: $!\n";
      file_lock($api);
      $ret_val = <$api>;
      file_unlock($api);
      close API;
      print "\n";
      return $ret_val;
    } else {
    # If the file hasn't been updated, go ahead and wait patiently
      print '.';
      sleep $sleep_interval;
    }
  }
}

sub draft_pack {
  my $line = shift @_;
  $line = sanitize_line($pattern, $line);
  @cards = split /\|/, $line;
  foreach $card (@cards) {
    $fewest = fewest_cards($card, $fewest);
    $best_plat  = best_plat($card, $best_plat);
    $best_gold  = best_gold($card, $best_gold);
  }
  print "=====\n";
  # Print out our info
  print "For line [$line],\n\t- plat winner:  " . get_card_info($best_plat);
  print "\t- gold winner:  " . get_card_info($best_gold);
  print "\t- count winner: " . get_card_info($fewest);
  $best_plat = "";
  $best_gold = "";
  $fewest = "";
  # If this is the last pick from the pack, calculate the value of the picks, and modify total profit based on that
  if($#cards == 0) {
    # Go ahead and add this to the pack value right now
    $pack_plat_total += $card_info{$best_plat}{'plat'};
    my $pack_profit = $pack_plat_total - $booster_value;
    $current_profit += $pack_profit;
    print "This pack's value was: " . $pack_plat_total . "p.  Pack profit was " . $pack_profit . "p. Total profit is ". $current_profit . "p\n";
  # If this is a beginning back, go ahead and reset the $pack_plat_total to 0 so we can start again
  } elsif ($#cards == 14) {
    pdebug "Resetting pack_plat_total";
    $pack_plat_total = 0;
  }
}

sub watch_file {
  while(1) {
    # Wait for new connection
    $line = read_api_file();
    chomp $line;
    # Grab the DraftPack lines 
    if ($line =~ /DraftPack/) {
      draft_pack($line);
    # Handle Draft Pick events
    } elsif ($line =~ /DaraftCardPicked/) {
      pdebug "line is $line";
      my $cname = (split /\"/, $line)[6];
      $cname =~ s/\\$//;
      pdebug "Incrementing $cname quantity";
      pdebug "count was $card_info{$cname}{'count'}";
      $card_info{$cname}{'count'} += 1;
      pdebug "count is now $card_info{$cname}{'count'}";
      # Increment total pack value by the plat value of the card
      $pack_plat_total += $card_info{$cname}{'plat'};
    # Handle Collection events
    } elsif ($line =~ /Collection/) {
      # Schedule a collection update.
      # Tick the update box
      $collection_pending = 1;
      # Stuff the collection line into the right place
      $collection_info = $line;
      # And schedule it for 3 seconds from now...
      alarm 3;
      # We schedule this for 3 seconds from now so we can put in a small time buffer
      # to help avoid a) delays involved in multiple attempts at writing collections over and 
      # over, b) suck in data as fast as possible to keep the script from bottlenecking the
      # Hex client, c) avoiding buffering data and causing RAM use to explode  and d) trying 
      # to prevent multiple attempts to write at once
      print 'C';
    # Start incrementing a timer so we can get a general idea of how long games are taking
    } elsif ($line =~ /GameStarted/) {
      print "Started game with following line: $line\n";
      $game_timer = time();  # Set game_timer to the current time
    } elsif ($line =~ /GameEnded/) {
      print "Finished game with following line: $line\n";
      # If we actually have a game start time that isn't the epoch, show how long the game lasted
      if ($game_timer != 0) {
        # Set end to the current time
        $end = time();  
        # Figure out how many seconds elapsed between the start of game and now
        $elapsed = $end - $game_timer;   
        # Make a call to the handy conversion function to print out the elapsed time in human readable form
        $elapsed_str = seconds_to_human($elapsed);
        print "$elapsed_str\n";
      }
    # All the other lines. . . print out '.'s so we have some idea of how much extra stuff is 
    # getting sent
    } else {
      print "Got this as a line: '$line'\n";
    }
    sleep 1;
  }
}

sub seconds_to_human {
  my $time = shift @_;
  my $ret_string = "";
  my $hours = int($time/3600);
  my $leftover = $time % 3600;
  my $minutes = int($leftover / 60);
  my $seconds = $leftover % 60;
  if($hours > 0) {
    $ret_string .= "$hours hours, ";
  }
  $ret_string .= "$minutes mins, $seconds secs";
  return $ret_string;
}

sub read_prices {
  $file = shift @_;
  return unless defined $file;
  @card_prices = ();
  %ret = {};
  open(IN,$file) || die "Can't open $file for reading: $!\n";
  @card_prices = <IN>;
  close IN;
  foreach $line (@card_prices) {
    chomp $line;
    #print "line is $line\n";
    @bits = split / +- +/, $line;
    next unless defined @bits[1];
    $ret{$bits[1]}{'count'} = $bits[0];
    $bits[2] =~ s/ PLATINUM//;
    $ret{$bits[1]}{'plat'} = $bits[2];
    $bits[3] =~ s/ GOLD//;
    $ret{$bits[1]}{'gold'} = $bits[3]
  }
  print "Price and collection data updated\n";
  return %ret;
}

sub calculate_booster_price {
  my $total = 100;
  # Right now, drafts are 2-2-1, so we sum those, add 100, then divide by 3. That's the EV we need to
  # extract from each draft
  $total += $card_info{'Set 002 Booster Pack'}{'plat'};
  $total += $card_info{'Set 002 Booster Pack'}{'plat'};
  $total += $card_info{'Set 001 Booster Pack'}{'plat'};
  pdebug "Total price for draft is $total plat";
  $booster_value = int($total / 3);
  pdebug "Based on this, each booster should return $booster_value plat to break even";
}

# Simple shell out to a script that does this. Maybe integrate it later, but for now having
# external is fine
sub update_counts_and_prices {
  my $arg = shift @_;
  # Put some checking in here for if this exists as well as exit codes and such
  print "Running mk_price_and_count_data.sh\n";
  system("./mk_price_and_count_data.sh $arg");
  print "Done running mk_price_and_count_data.sh\n";
}

my $mk_arg = '';
if ($ARGV[0] =~ /-q/) {
  $mk_arg = 'nodl';
} elsif ($ARGV[0] =~ /-DEBUG/) {
  $mk_arg = 'DEBUG';
} else {
  $mk_arg = '';
}
update_counts_and_prices($arg);

%card_info = read_prices($price_file);

calculate_booster_price;

watch_file('DraftPack');
