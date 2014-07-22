#!/usr/bin/env ruby
#
# get prices for rare and legendary cards for both gold and platinum from Hex price data

$: << "/home/docxstudios/web/hex/code"
require 'prices'

####### MAIN SECTION
foo = Hex::Collection.new
con = foo.get_db_con
lines = read_db(con, "and c.rarity regexp 'Legendary|Rare'")                      # Get data from database
parse_lines(lines, true)                        # Compile that data into a useable form
puts '<head><link rel="stylesheet" type="text/css" href="/hex/tables.css"></head>'
puts '<body>'
puts "<h2>Usage notes:</h2>"
puts "The lines below have the following fields separated by the '|' character:\n<ul>"
puts "<li> Card name"
puts "<li> Currency name (likely PLATINUM)"
puts "<li> average price without outlier data"
puts "<li> number of auctions"
puts "<li> average price with outlier data"
puts "<li> minimum"
puts "<li> first quartile"
puts "<li> median"
puts "<li> third quartile"
puts "<li> maximum"
puts "<li> excluded outlier values"
puts "<li> Currency name (likely GOLD)"
puts "<li> The same fields for the GOLD auctions that were done for the PLATINUM auctions"
puts "</ul>"
puts ""
puts "<b>NOTE:</b> If a data set has less than 9 auctions, no outliers are excluded and the average prices with and without outliers will be the same. You will see empty cells in the table since I don't extract those details for such a small sample size."
puts "<p><b>====== LEGENDARY CARDS ======</b>"
print_filtered_detailed_output(@card_names, '\[Legendary\]')
puts ""
puts "<p><b>====== RARE CARDS ======</b>"
print_filtered_detailed_output(@card_names, '\[Rare\]')
puts "</pre></body></html>"
