#!/usr/bin/perl
#
# Take Hex API Draft data and use it to provide pick guidance based on current market value

%card_info  = {};
$price_file = 'price_and_count_data.out';
$best_gold  = "";
$best_plat  = "";
$fewest     = "";

sub fewest_cards {
  $first = shift @_;
  $second = shift @_;
#  print "Checking first: '$first' and second: '$second'\n";
  if (! defined $second || $second eq '') {
#    print "Returning $first\n";
    return $first;
  }
  $field = 'count';
#  print "Comparing $first $field: $card_info{$first}{$field} and $second $field: $card_info{$second}{$field}\n";
  if(int($card_info{$first}{$field}) < int($card_info{$second}{$field})){
#    print "Returning $first\n";
    return $first;
  }
#  print "Returning $second\n";
  return $second;
}

sub best_plat {
  $first = shift @_;
  $second = shift @_;
  $field = 'plat';
  return which_is_larger($first, $second, $field);
}

sub best_gold {
  $first = shift @_;
  $second = shift @_;
  $field = 'gold';
  return which_is_larger($first, $second, $field);
}

sub which_is_larger {
  $first = shift @_;
  $second = shift @_;
  $field = shift @_;
  if(int($card_info{$first}{$field}) > int($card_info{$second}{$field})){
    return $first;
  }
  return $second;
}

# Strip out bits from line and make it pipe delimited
sub sanitize_line {
  my $pat = shift @_;
  my $line = shift @_;
#  print "This is the patern: $pat\n";
  chomp $line;
#  print "This is the line: $line\n";
  $line =~ s/^.+$pattern\\?",\\?"[^"]+",\[\\?"//;
  #$line =~ s/^.+$pattern\\?",\\?"[^"]+//;
#  print "1-> $line ->\n";
  $line =~ s/[\\"\]]+$//;
#  print "2-> $line ->\n";
  $line =~ s/\\?",\\?"/|/g;
  $line =~ s/,//g;
#  print "3-> $line ->\n";
#  print "== $line\n";
  return $line;
}

sub get_card_info {
  $name = shift @_;
  $info = "'$name' [Qty: $card_info{$name}{'count'}] - $card_info{$name}{'plat'}p and $card_info{$name}{'gold'}g\n";
  return $info;
}

sub watch_for {
  $pattern = shift @_;
  $no_data = 0;
  print "Looking at STDIN for Draft Data\n";
  while($line=<>) {
    if ($line=~ /$pattern/) {
      print "\n" if $no_data;
      $line = sanitize_line($pattern, $line);
      @cards = split /\|/, $line;
      foreach $card (@cards) {
#        print "Checking cards\n";
#        print " C - $card " . get_card_info($card);
#        print " F - $fewest " . get_card_info($fewest);
#        print " P - $best_plat " . get_card_info($best_plat);
#        print " G - $best_gold " . get_card_info($best_gold);
        $fewest = fewest_cards($card, $fewest);
        $best_plat  = best_plat($card, $best_plat);
        $best_gold  = best_gold($card, $best_gold);
#        print " F - $fewest " . get_card_info($fewest);
#        print " P - $best_plat " . get_card_info($best_plat);
#        print " G - $best_gold " . get_card_info($best_gold);
#        print " \n";
      }
      # Clear screen
#      print "\033[2J";    #clear the screen
#      print "\033[0;0H"; #jump to 0,0
      print "=====\n";
      # Print out our info
      print "For line [$line],\n";
      print "\t- plat winner:  ";
      print get_card_info($best_plat);
      print "\t- gold winner:  ";
      print get_card_info($best_gold);
      print "\t- count winner: ";
      print get_card_info($fewest);
      $best_plat = "";
      $best_gold = "";
      $fewest = "";
    } else {
      print '.';
      $no_data = 1;
    }
  }
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
  return %ret;
}

# Simple shell out to a script that does this. Maybe integrate it later, but for now having
# external is fine
sub update_prices {
  # Put some checking in here for if this exists as well as exit codes and such
  system("./mk_price_and_count_data.sh");
}

print "Updating price data\n";
update_prices();
print "Price data updated\n";
%card_info = read_prices($price_file);
print "Read in card price info\n";

watch_for('DraftPack');
