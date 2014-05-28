#!/usr/bin/env ruby
#
# Test out the Hex module

require 'cgi'

cgi = CGI.new
params = cgi.params

# Set default for output format
output_format = 'html_table'
# See if we were specifically told to use an output_format If so, change output_format variable to that and remove 
# the parameter from the params hash (so we don't try to use it as a search parameter)
unless params['output_format'].empty?
  output_format = params['output_format'][0]
  params.delete('output_format')
end

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
puts "X-Search-Query: #{query}"
puts "X-Output-Format: #{output_format}"
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
puts '<a href="/hex/">Search Again?</a>'
if output_format =~ /html/
  puts '<div class="CSSTableGenerator" > '
  puts '<table>'
else
  puts '<pre>'
end
#puts Hex::Card.dump_html_table_header
puts Hex::Card.send("dump_#{output_format}_header")
foo.cards.sort {|a, b| a.card_number.to_i <=> b.card_number.to_i}.each do |card|
  puts card.send("to_#{output_format}")
end

if output_format =~ /html/
  puts '</table>'
else
  puts '</pre>'
end

puts '<a href="/hex/">Search Again?</a>'

#binding.pry
