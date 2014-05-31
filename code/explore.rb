#!/usr/bin/env ruby
#
#  Explore ways to futz around with the Hex module

require "pry"
$: << "/home/docxstudios/web/hex/code"
require "Hex_test"
foo = Hex::Collection.new
con = foo.get_db_con
query = '1 = 1' # Simple query to get everything
#search = "rarity regexp 'Legendary' OR rarity regexp 'Rare'"
foo.load_collection_from_search(con, query)

types = foo.card_trait_list('type')

binding.pry
