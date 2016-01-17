#!/usr/bin/env ruby
#
# get distribution of prices for card for both gold and platinum from Hex price data

require 'json'

json_file = "/home/docxstudios/web/hex/all_prices_json.txt"
json = File.read(json_file)
blob = JSON.parse(json)
cards = blob["cards"]

puts "Content-type: text\plain\n\n"
puts '"Name","Rarity","Currency",Weighted Average Price,# of Auctions,Average Price,Min price,Lower Quartile,Median,Upper Quartile,Maximum Price,"Excluded Prices","Currency",Weighted Average Price,# of Auctions,Average Price,Min price,Lower Quartile,Median,Upper Quartile,Maximum Price,"Excluded Prices",UUID'

cards.sort_by {|c| c["name"].to_s }.each do |c| 
  next if c["name"].nil?
  puts "\"#{c["name"]}\",\"#{c["rarity"]}\",\"PLATINUM\",#{c["PLATINUM"]["avg"]},#{c["PLATINUM"]["sample_size"]},#{c["PLATINUM"]["true_avg"]},#{c["PLATINUM"]["min"]},#{c["PLATINUM"]["lq"]},#{c["PLATINUM"]["med"]},#{c["PLATINUM"]["uq"]},#{c["PLATINUM"]["max"]},\"#{c["PLATINUM"]["excl"]}\",\"GOLD\",#{c["GOLD"]["avg"]},#{c["GOLD"]["sample_size"]},#{c["GOLD"]["true_avg"]},#{c["GOLD"]["min"]},#{c["GOLD"]["lq"]},#{c["GOLD"]["med"]},#{c["GOLD"]["uq"]},#{c["GOLD"]["max"]},\"#{c["GOLD"]["excl"]}\",#{c["uuid"]}"
end
exit

