#!/usr/bin/env ruby
#
# get distribution of prices for card for both gold and platinum from Hex price data

$: << "/home/docxstudios/web/hex/code"
require 'Hex'
require 'pry'

####### MAIN SECTION
puts "Content-type: text\plain\n"

puts "Name ... Avg_price Currency [# of auctions] ... Avg_price Currency [# of auctions]"

foo = Hex::Collection.new

prices = foo.get_local_price_info
lines = foo.get_card_list_from_db('rarity = "Common" AND type NOT LIKE "Equipment"')
foo.print_local_info_for_cardlist(lines, prices)


