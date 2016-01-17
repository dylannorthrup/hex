#!/usr/bin/env ruby
#
# get prices for rare and legendary cards for both gold and platinum from Hex price data

$: << "/home/docxstudios/web/hex/code"
require 'Hex'

####### MAIN SECTION
puts "Content-type: text\plain\n"

foo = Hex::Collection.new

prices = foo.get_local_price_info
lines = foo.get_card_list_from_db('rarity = "Legendary" AND type NOT LIKE "Equipment"')
puts "====== LEGENDARY CARDS ======"
puts "Name ... Avg_price Currency [# of auctions] ... Avg_price Currency [# of auctions]"
foo.print_local_info_for_cardlist(lines, prices)

lines = foo.get_card_list_from_db('rarity = "Legendary" AND type NOT LIKE "Equipment"')
puts "====== RARE CARDS ======"
puts "Name ... Avg_price Currency [# of auctions] ... Avg_price Currency [# of auctions]"
foo.print_local_info_for_cardlist(lines, prices)
exit

