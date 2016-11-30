#!/usr/bin/perl
#
# Take processed draft data and print out draft probabilities

use strict;
use Data::Dumper;
use Hex;

my $pack_cards = 17;
my %pick_locs;
my $log_file;

# Get two database handles.... one for reading, one for writing
my $rdbh = get_dbh();
my $wdbh = get_dbh();

my %data;

print "Beginning draft chance updates\n";
my $read_query = "SELECT uuid, picks from draft_data";
my $sth = $rdbh->prepare($read_query);
$sth->execute();
while (my $ref = $sth->fetchrow_hashref()) {
#  print "uuid: $ref->{'uuid'} - picks: $ref->{'picks'}\n";
  my $wheel_probs = wheel_probs($ref->{'picks'});
  my $update_query = "UPDATE draft_data SET chances = '$wheel_probs' WHERE uuid LIKE '$ref->{'uuid'}'";
  $wdbh->do($update_query);
}
print "Draft chance updates complete\n";
exit;

# SQL Query: select c.name, d.picks from cards c, draft_data d where c.uuid = d.uuid;

#print Dumper(%data);
#pry();
foreach my $u (keys %data) {
  my $name = `curl -sS http://doc-x.net/hex/uuid_to_name.rb?$u`;
  chomp($name);
  $name = "UNKNOWN" if $name =~ /No value exists for key/;
  print "$u ($name): ";
}
