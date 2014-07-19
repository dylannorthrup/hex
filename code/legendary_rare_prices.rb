#!/usr/bin/env ruby
#
# get prices for rare and legendary cards for both gold and platinum from Hex price data

$: << "/home/docxstudios/web/hex/code"
require 'prices'

####### MAIN SECTION
foo = Hex::Collection.new
con = foo.get_db_con
lines = read_db(con, "and c.rarity regexp 'Legendary|Rare'")                      # Get data from database
parse_lines(lines)                        # Compile that data into a useable form
print_filtered_output(@card_names, '\[Legendary\]')
print_filtered_output(@card_names, '\[Rare\]')
