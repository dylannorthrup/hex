#!/usr/bin/env ruby
#
# Grab cards and dump them to SQL

if ARGV[0].nil? then
  puts "Must pass in a set as an option."
  puts "Example: 'Set001'"
  puts "Exiting"
  exit
end


$: << "/home/docxstudios/web/hex/code"
require "Hex"
foo = Hex::Collection.new
foo.load_set(set_name=ARGV[0])

puts Hex::Card.dump_sql_header
foo.cards.sort {|a, b| a.card_number.to_i <=> b.card_number.to_i}.each do |card|
  puts "#{card.to_sql}"
#  puts "select name from cards where uuid = '#{card.uuid}';"
end


#binding.pry
