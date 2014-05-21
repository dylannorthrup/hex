#!/usr/bin/env ruby
#
# Test out the Hex module

# Print out HTTP headers
puts "Content-type: text/html"
puts ""

require 'pry'
$: << "/home/docxstudios/web/hex/code"
require "Hex"
require "mysql"
#results = con.query("Select distinct set_id from cards")
#results.each do |row|
#  puts row
#end

foo = Hex::Collection.new
con = foo.get_db_con
foo.load_collection(con)

puts "<head>"
puts '<link rel="stylesheet" type="text/css" href="/hex/tables.css">'
puts "</head>"

puts '<div class="CSSTableGenerator" > '
puts '<table>'
puts Hex::Card.dump_html_table_header
foo.cards.sort {|a, b| a.card_number.to_i <=> b.card_number.to_i}.each do |card|
  puts "#{card.to_html_table}"
end

puts '</table>'

#binding.pry
