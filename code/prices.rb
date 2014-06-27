#!/usr/bin/env ruby
#
# Test out ERB templating

# Print out HTTP headers
puts "Content-type: text/plain"
puts ""

require 'open-uri'
require 'json'
require 'pp'

spreadsheet_url = '/home/docxstudios/web/hex/code/spreadsheet.json'

raw_data = open(spreadsheet_url).read

# Have to trim off the first bit and last bit of the string we get back from Google
raw_data.gsub!(/^google.visualization.Query.setResponse\(/, '')
raw_data.gsub!(/\);$/, '')

# Parse the json into a data structure we can access
data_json = JSON.parse(raw_data)

# Grab out the array of rows
rows = data_json['table']['rows']

# Go through each row.  If we don't have at least four, add the card info to the needed array
needed = Array.new
rows.each do |row|
  name = row['c'][0]['v']
  rarity = row['c'][2]['v']
  shard = "[#{row['c'][3]['v']}]"
  price = "NO DATA"
  price = row['c'][7]['v'] unless row['c'][7].nil?
  next unless rarity =~ /Legendary|Rare/
  value = "#{'%-9.9s' % rarity} - #{'%-20.20s' % name} #{'%-10.10s' % shard} -> #{price}"
  needed << value
end

puts "Approximate prices for Rare and Legendary Hex Cards"
puts ""

needed.sort.each do |row|
  puts row
end

puts ""
puts "This data is as accurate as any manually entered data put in whenever the maintainer can do it can be."
puts "Take with an appropriate number of grais of salt."
