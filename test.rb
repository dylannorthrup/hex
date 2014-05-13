#!/usr/local/opt/ruby/bin/ruby
#
# Test out the Hex module

require "pry"
require "/Users/dnorthrup/temp/btsync/hex/Hex.rb"
foo = Hex::Collection.new
foo.load_set('Set001')

puts "My collection has #{foo.size} cards in it"
puts "Here's what it looks like:"
foo.cards.sort {|a, b| a.card_number <=> b.card_number}.each do |card|
  # Skip non collectible cards (which all have card_number of 0)
  next if card.card_number == 0
#  puts "Card: #{card}"
  puts "#{card.to_csv}"
end

#binding.pry
