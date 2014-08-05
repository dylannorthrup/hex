#!/usr/bin/env ruby
#
# Test out ERB templating

# Print out HTTP headers
puts "Content-type: text/plain"
puts ""

require 'open-uri'
require 'json'
require 'pp'
#spreadsheet_url = 'https://docs.google.com/spreadsheets/d/1_8qzXrlpBnucl5H9tybuJr0Lntl9ydFqtaHvleQJJ4I/gviz/tq?tq'
spreadsheet_url = '/home/docxstudios/web/hex/code/spreadsheet.json'

raw_data = open(spreadsheet_url).read

#puts "Got data from remote source"

# Have to trim off the first bit and last bit of the string we get back from Google
raw_data.gsub!(/^google.visualization.Query.setResponse\(/, '')
raw_data.gsub!(/\);$/, '')

#puts "Data massaged"

# Parse the json into a data structure we can access
data_json = JSON.parse(raw_data)
#puts "Data parsed"

# Grab out the array of rows
rows = data_json['table']['rows']

# Go through each row.  If we don't have at least four, add the card info to the needed array
needed = Array.new
surplus = Array.new
rows.each do |row|
  name = row['c'][0]['v']
  count = row['c'][1]['f'].to_i
  rarity = row['c'][2]['v']
  shard = "[#{row['c'][3]['v']}]"
  price = "NO DATA"
  price = row['c'][6]['v'] unless row['c'][6].nil?
  gprice = "NO DATA"
  gprice = row['c'][7]['v'] unless row['c'][7].nil?
  next unless rarity =~ /Legendary|Rare/
#  puts "Testing #{name} with count of #{count}"
  if count < 4
    value = "#{'%-9.9s' % rarity} - #{'%-20.20s' % name} #{4 - count} #{'%-10.10s' % shard} -> need #{4 - count} w/ price of #{price.to_i} plat [#{gprice.to_i} gold]"
    needed << value
  end
  if count > 4
    value = "#{'%-9.9s' % rarity} - #{'%-20.20s' % name} #{count - 4} #{'%-10.10s' % shard} -> have #{count - 4} extra w/ price of #{price.to_i} plat [#{gprice.to_i} gold]"
    surplus << value
  end
end

#puts "Extracted rows into needed array"

puts "========== NEEDS =========================================================================================="
needed.sort.each do |row|
  puts row
end

puts "\n\n========== EXTRAS =========================================================================================="
surplus.sort.each do |row|
  puts row
end

