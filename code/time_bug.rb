#!/usr/bin/env ruby
#
# Test out the Hex module

# Print out HTTP headers
puts "Content-type: text/html"
puts ""

require "pry"
$: << "/home/docxstudios/web/hex/code"
require "Hex"
foo = Hex::Collection.new
#foo.load_set('Set001')
con = foo.get_db_con
foo.load_collection(con)

view = Hex::CardView.new()

#puts "SET NUMBER|CARD NUMBER|NAME|RARITY|COLOR|TYPE|SUB TYPE|FACTION|SOCKET COUNT|COST|ATK|HEALTH|TEXT|FLAVOR|RESTRICTION|ARTIST|ENTERS PLAY EXHAUSTED"
foo.cards.sort {|a, b| a.card_number <=> b.card_number}.each do |card|
  #next unless card.name =~ /Time Bug|Replicator's Gambit|Hex Engine/
  next unless card.type =~ /Action|Constant/
  puts card.fill_template()
end

#binding.pry
