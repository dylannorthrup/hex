#!/usr/bin/env ruby
#
# get prices for PVE cards for both gold and platinum from Hex price data

$: << "/home/docxstudios/web/hex/code"
require 'Hex'

foo = Hex::Collection.new
foo.get_local_price_info
foo.print_local_price_info_for_set("PVE0[0-9]+")
