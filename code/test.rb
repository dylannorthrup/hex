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

puts "My collection has #{foo.size} cards in it"
puts "Here's what it looks like:"
foo.cards.sort {|a, b| a.card_number.to_i <=> b.card_number.to_i}.each do |card|
  # Skip non collectible cards (which all have card_number of 0)
  next if card.card_number == "0"
  puts "#{card.to_csv}"
end

#binding.pry
