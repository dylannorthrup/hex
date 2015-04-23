#!/usr/bin/env ruby
#
# get prices for rare and legendary cards for both gold and platinum from Hex price data

$: << "/home/docxstudios/web/hex/code"
require 'prices'

####### MAIN SECTION
foo = Hex::Collection.new
con = foo.get_db_con
filter = "and c.rarity regexp 'Legendary|Rare' and c.set_id regexp '^002$'"
lines = read_db(con, filter)   # Get data from database
parse_lines(lines)             # Compile that data into a useable form
#puts "====== LEGENDARY CARDS ======"
print_pdcsv_output(@card_names, '\[Legendary\]', ' AA\' \[')
#puts ""
#puts "====== RARE CARDS ======"
print_pdcsv_output(@card_names, '\[Rare\]', ' AA\' \[')
