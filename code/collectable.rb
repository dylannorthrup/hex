#!/usr/bin/env ruby
#
# Test out the Hex module

# Print out HTTP headers
puts "Content-type: text/plain"
puts ""

#require "pry"
$: << "/home/docxstudios/web/hex/code"
require "Hex"
foo = Hex::Collection.new
con = foo.get_db_con
foo.load_collection(con)

puts "SET NUMBER|CARD NUMBER|NAME|RARITY|COLOR|TYPE|SUB TYPE|FACTION|SOCKET COUNT|COST|ATK|HEALTH|TEXT|FLAVOR|RESTRICTION|ARTIST|ENTERS PLAY EXHAUSTED"
foo.cards.sort {|a, b| a.card_number <=> b.card_number}.each do |card|
  # Skip non collectible cards (which all have card_number of 0)
#  next if card.card_number == 0
#  puts "Card: #{card}"
  puts "#{card.to_csv}"
end

#binding.pry
