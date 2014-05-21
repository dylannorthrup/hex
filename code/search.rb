#!/usr/bin/env ruby
#
# Test out the Hex module

require 'cgi'

cgi = CGI.new
params = cgi.params

# If we didn't get any search parameters, redirect to the search page
if params.empty?
  target_url = "http://doc-x.net/hex/"
  # Use cgi.out and construct headers on the fly
  cgi.out( "status" => "REDIRECT", "Location" => target_url, "type" => "text/html") {
    "Redirecting to search page: #{target_url}\n"
  }
  exit
end


# So, we've got some parameters.  Let's construct a query based on that.
require 'mysql'
query = '1 = 1'
params.each_pair do |k, v_ary|
#  puts "X-Query-DEBUG: key: #{k} and value: #{v} and query so far: #{query}"
  next unless k =~ /^[\w_]+$/  # Checking to make sure keys are sanely constructed (letters and underscores)
  v = v_ary[0]  # Extract out the value of the query
  next if v =~ /^-Any-$/    # Skip values that say '-Any-'
  next if v =~ /^\s*$/      # Skip values that are blank
#  puts "X-Query-DEBUG: PASSED key validation"
  v = CGI.unescape v
  v = Mysql.escape_string v
  query += " AND "
  query += "#{k} regexp '#{v}'"
#  puts "X-Query-DEBUG: key: #{k} and value: #{v} and query so far: #{query}"
end
query += ";"

# Print out HTTP headers
puts "Content-type: text/html"
#puts "X-Search-Params: #{params}"
puts "X-Search-Query: #{query}"
puts ""

#require "pry"
$: << "/home/docxstudios/web/hex/code"
require "Hex"
foo = Hex::Collection.new
con = foo.get_db_con
#search = "rarity regexp 'Legendary' OR rarity regexp 'Rare'"
foo.load_collection_from_search(con, query)

puts "<head>"
puts '<link rel="stylesheet" type="text/css" href="/hex/tables.css">'
puts "</head>"
puts '<h1>Search Results</h1>'
#puts "Here's the search query: #{query}"
puts '<a href="/hex/">Search Again?</a>'
puts '<div class="CSSTableGenerator" > '
puts '<table>'
puts '  <tr>'
puts '    <td>SET NUMBER</td>'
puts '    <td>CARD NUMBER</td>'
puts '    <td>NAME</td>'
puts '    <td>RARITY</td>'
puts '    <td>COLOR</td>'
puts '    <td>TYPE</td>'
puts '    <td>SUB TYPE</td>'
puts '    <td>FACTION</td>'
puts '    <td>SOCKET COUNT</td>'
puts '    <td>COST</td>'
puts '    <td>THRESHOLD SHARD</td>'
puts '    <td>THRESHOLD NUMBER</td>'
puts '    <td>ATK</td>'
puts '    <td>HEALTH</td>'
puts '    <td>TEXT</td>'
puts '    <td>FLAVOR</td>'
puts '    <td>RESTRICTION</td>'
puts '    <td>ARTIST</td>'
puts '    <td>ENTERS PLAY EXHAUSTED</td>'
puts '    <td>UUID</td>'
puts '  </tr>'
foo.cards.sort {|a, b| a.card_number.to_i <=> b.card_number.to_i}.each do |card|
  puts "#{card.to_html_table}"
end

puts '</table>'

puts '<a href="/hex/">Search Again?</a>'

#binding.pry
