#!/usr/bin/env ruby
#
# Grab cards and dump them to SQL

$: << "/home/docxstudios/web/hex/code"
require "Hex_test"
foo = Hex::Collection.new
#foo.load_collection
foo.load_set(set_name='Set02_PVP')

puts Hex::Card.dump_sql_header
foo.cards.sort {|a, b| a.card_number.to_i <=> b.card_number.to_i}.each do |card|
  puts "#{card.to_sql}"
#  puts "select name from cards where uuid = '#{card.uuid}';"
end


#binding.pry
