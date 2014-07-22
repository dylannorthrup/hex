#!/usr/bin/env ruby
#
# get distribution of prices for card for both gold and platinum from Hex price data

$: << "/home/docxstudios/web/hex/code"
require 'prices'

####### MAIN SECTION
foo = Hex::Collection.new
con = foo.get_db_con
lines = read_db(con)                      # Get data from database
parse_lines(lines)                        # Compile that data into a useable form
print_csv_output(@card_names)
