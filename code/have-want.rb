#!/usr/bin/env ruby
#
# Test out ERB templating

# Print out HTTP headers
puts "Content-type: text/plain"
puts ""

require 'pry'
require 'open-uri'
require 'json'
require 'pp'
#spreadsheet_url = 'https://docs.google.com/spreadsheets/d/1_8qzXrlpBnucl5H9tybuJr0Lntl9ydFqtaHvleQJJ4I/gviz/tq?tq'
spreadsheet_urls = [ '/home/docxstudios/web/hex/code/hex_collection_sheet2.json', '/home/docxstudios/web/hex/code/hex_collection_sheet1.json' ]

needed = Array.new
surplus = Array.new

spreadsheet_urls.each do |spreadsheet_url|
  raw_data = open(spreadsheet_url).read

  #puts "Got data from remote source"

  # Have to trim off the first bit and last bit of the string we get back from Google
  raw_data.gsub!(/^google.visualization.Query.setResponse\(/, '')
  raw_data.gsub!(/\);$/, '')

  #puts "Data massaged"
  
  # Parse the json into a data structure we can access
  data_json = JSON.parse(raw_data)
  #puts "Data parsed"

#  binding.pry

  # Grab out the array of rows
  rows = data_json['feed']['entry']

  # Go through each row.  If we don't have at least four, add the card info to the needed array
  rows.each do |row|
    name = row['gsx$name']['$t']
    count = row['gsx$count']['$t'].to_i
    rarity = row['gsx$rarity']['$t']
    shard = "[#{row['gsx$shard']['$t']}]"
#    price = "NO DATA"
#    price = row['c'][6]['v'] unless row['c'][6].nil?
#    gprice = "NO DATA"
#    gprice = row['c'][7]['v'] unless row['c'][7].nil?
    next unless rarity =~ /Legendary|Rare/
  #  puts "Testing #{name} with count of #{count}"
    if count < 4
      value = "#{'%-9.9s' % rarity} - #{'%-40.40s' % name} Want #{4 - count} "
      needed << value
    end
    if count > 4
      value = "#{'%-9.9s' % rarity} - #{'%-40.40s' % name} Have #{count - 4} for trade"
      surplus << value
    end
  end
  
  #puts "Extracted rows into needed array"
end

puts "========== WANTS =========================================="
needed.sort.each do |row|
  puts row
end

puts "\n\n========== HAVES ===================================================="
surplus.sort.each do |row|
  puts row
end

