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
foo.load_set('Set001')

puts "SET NUMBER|CARD NUMBER|NAME|RARITY|COLOR|TYPE|SUB TYPE|FACTION|SOCKET COUNT|COST|ATK|HEALTH|TEXT|FLAVOR|UNLIMITED|UNIQUE|ARTIST|ENTERS PLAY EXHAUSTED"
foo.cards.sort {|a, b| a.card_number <=> b.card_number}.each do |card|
  puts "#{card.to_csv}"
end

#binding.pry