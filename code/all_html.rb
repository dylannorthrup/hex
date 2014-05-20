#!/usr/bin/env ruby
#
# Test out the Hex module

# Print out HTTP headers
puts "Content-type: text/html"
puts ""

$: << "/home/docxstudios/web/hex/code"
require "Hex"
foo = Hex::Collection.new
foo.load_set('Set001')

puts "<head>"
puts '<link rel="stylesheet" type="text/css" href="/hex/tables.css">'
puts "</head>"

puts '<div class="CSSTableGenerator" > '
puts '<table>'
puts '  <tr>'
puts '    <td>SET NUMBER</td>'
puts '    <td>CARD NUMBER</td>'
puts '    <td>NAME</td>'
puts '    <td>RARITY</td>'
puts '    <td>COLOR</td>'
puts '    <td>TYPE</td>'
puts '    <td>SUB TYPE</td>'
puts '    <td>FACTION</td>'
puts '    <td>SOCKET COUNT</td>'
puts '    <td>COST</td>'
puts '    <td>ATK</td>'
puts '    <td>HEALTH</td>'
puts '    <td>TEXT</td>'
puts '    <td>FLAVOR</td>'
puts '    <td>UNLIMITED</td>'
puts '    <td>UNIQUE</td>'
puts '    <td>ARTIST</td>'
puts '    <td>ENTERS PLAY EXHAUSTED</td>'
puts '    <td>UUID</td>'
puts '  <tr>'
foo.cards.sort {|a, b| a.card_number.to_i <=> b.card_number.to_i}.each do |card|
  puts "#{card.to_html_table}"
end

puts '</table>'

#binding.pry
