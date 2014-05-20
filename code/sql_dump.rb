#!/usr/bin/env ruby
#
# Grab cards and dump them to SQL

$: << "/home/docxstudios/web/hex/code"
require "Hex"
foo = Hex::Collection.new
#foo.load_set('Set001')
foo.load_collection

puts Hex::Card.new.dump_sql_table_format
foo.cards.sort {|a, b| a.card_number.to_i <=> b.card_number.to_i}.each do |card|
  puts "#{card.to_sql}"
#  puts "select name from cards where uuid = '#{card.uuid}';"
end


#binding.pry
