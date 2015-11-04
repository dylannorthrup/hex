#!/usr/bin/env ruby
#
# get distribution of prices for card for both gold and platinum from Hex price data

puts "Content-type: text\plain\n"

puts "Name ... Avg_price Currency [# of auctions] ... Avg_price Currency [# of auctions]"

File.open("/home/docxstudios/web/hex/all_prices_csv.txt").each_line { |line|
  line.chomp!
  if   line.match(/^"([^"]+)",.*,"PLATINUM",(\d+),(\d+),.*"GOLD",(\d+),(\d+).*,([^,]+)$/) then
    name = $1
    pavg = $2
    pcount = $3
    gavg = $4
    gcount = $5
    uuid = $6
    puts "#{name} ... #{pavg} PLATINUM [#{pcount} auctions] ... #{gavg} GOLD [#{gcount} auctions]"
  end
}

