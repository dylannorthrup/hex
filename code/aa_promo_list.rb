#!/usr/bin/env ruby
#
# Dump out names and UUIDs for all Alternate Art/Promo cards

$: << "/home/docxstudios/web/hex/code"
require 'Hex'

####### MAIN SECTION
foo = Hex::Collection.new
con = foo.get_db_con
foo.load_collection_from_search(con, "rarity like 'Epic' order by name")
foo.cards.each do |c|
  puts "#{c.uuid} - #{c.name}"
end
#binding.pry
