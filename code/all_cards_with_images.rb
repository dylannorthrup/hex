#!/usr/bin/env ruby
#
# Test out the Hex module

# Print out HTTP headers
puts "Content-type: text/html"
puts ""

#require "pry"
$: << "/home/docxstudios/web/hex/code"
require "Hex"
foo = Hex::Collection.new
con = foo.get_db_con
foo.load_set('001', con)

foo.cards.sort {|a, b| a.card_number <=> b.card_number}.each do |card|
  puts card.send("to_html_card_table")
end

#binding.pry
