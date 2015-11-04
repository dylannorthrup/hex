#!/usr/bin/env ruby
#
# get distribution of prices for card for both gold and platinum from Hex price data

require 'pry'

puts 'Content-type: text/plain'
puts ''

puts "Name ... UUID ... Avg_price Currency [# of auctions] ... Avg_price Currency [# of auctions]"
File.open("/home/docxstudios/web/hex/all_prices_csv.txt").each_line { |line|
  line.chomp!
  if   line.match(/^"([^"]+)",.*,"PLATINUM",(\d+),(\d+),.*"GOLD",(\d+),(\d+).*,([^,]+)$/) then
    name = $1
    pavg = $2
    pcount = $3
    gavg = $4
    gcount = $5
    uuid = $6
    puts "#{name} ... #{uuid} ... #{pavg} PLATINUM [#{pcount} auctions] ... #{gavg} GOLD [#{gcount} auctions]"
  end
}


exit

#$: << "/home/docxstudios/web/hex/code"
#require 'prices'
#
######## MAIN SECTION
#foo = Hex::Collection.new
#con = foo.get_db_con
#lines = read_db_with_uuids(con)                      # Get data from database
#parse_lines(lines)                        # Compile that data into a useable form
#@output_type = 'UUIDPSV'
#@output_detail = 'brief'
#print_card_output(@card_names)
