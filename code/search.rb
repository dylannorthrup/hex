#!/usr/bin/env ruby
#
# Test out the Hex module

require 'fcgi'
require 'cgi'

cgi = CGI.new
params = cgi.params

# Move this up here so we can keep this outside the FCGI block
$: << "/home/docxstudios/web/hex/code"
require "Hex"
foo = Hex::Collection.new
con = foo.get_db_con

# Set default for output format
output_format = 'html_table'

fcgi_count = 0

FCGI.each_cgi do 
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
search_string = "output_format=#{output_format}"
params.each_pair do |k, v_ary|
#  puts "X-Query-DEBUG: key: #{k} and value: #{v} and query so far: #{query}"
  next unless k =~ /^[\w_]+$/  # Checking to make sure keys are sanely constructed (letters and underscores)
  v = v_ary[0]  # Extract out the value of the query
  next if v =~ /^-Any-$/    # Skip values that say '-Any-'
  next if v =~ /^\s*$/      # Skip values that are blank
#  puts "X-Query-DEBUG: PASSED key validation"
  # Quick thing here to translate set_id to the actual name for early sets
  if k =~ /set_id/ then
    case v
      when "004"
        v = "Primal Dawn"
      when "003"
        v = "Armies of Myth"
      when "002"
        v = "Shattered Destiny"
      when "001"
        v = "Shards of Fate"
    end
  end
  # Keep track of search terms for the "Get URL for this search" thing
  search_string = "#{search_string}&#{k}=#{v}"
  # Quick thing here to squash threshold_n and threshold_c to 'threshold'
  if k =~ /^threshold_(c|n)/ then 
    k = 'threshold'
  end
  v = CGI.unescape v
  v = Mysql.escape_string v
  # Quick thing to turn 'Common' into '^Common' so we don't accidentally match 'Uncommon' with the regexp
  if k == "rarity" then
    if v =~ /common/i then
      v = "^Common"
    end
  end
  query += " AND "
  query += "#{k} regexp '#{v}'"
#  puts "X-Query-DEBUG: key: #{k} and value: #{v} and query so far: #{query}"
end
query += ";"

# Print out HTTP headers
if output_format == "json" then
  puts "Content-type: application/javascript"
elsif output_format == "s" then
  puts "Content-type: text/plain"
else
  puts "Content-type: text/html"
end
puts "X-Search-Query: #{query}"
puts "X-Output-Format: #{output_format}"
puts ""

#$: << "/home/docxstudios/web/hex/code"
#require "Hex"
#foo = Hex::Collection.new
#con = foo.get_db_con
#search = "rarity regexp 'Legendary' OR rarity regexp 'Rare'"
foo.load_collection_from_search(con, query)

# This is for a bare-bones output style. Do this in plain-text
if output_format == "s"
  foo.cards.sort {|a, b| a.card_number.to_i <=> b.card_number.to_i}.each do |card|
    puts card.send("to_#{output_format}")
  end
  exit
end

# This is for json output.
if output_format == "json"
  string = "{ \"cards\": ["
  foo.cards.sort {|a, b| a.card_number.to_i <=> b.card_number.to_i}.each do |card|
    string += card.send("to_#{output_format}")
  end
  string.chomp!(',')
  string += "\n\t]\n}"
  puts string
  exit
end

puts "<head>"
puts '<link rel="stylesheet" type="text/css" href="/hex/tables.css">'
puts "</head>"
puts '<h1>Search Results</h1>'
puts "<a href='/hex/search.rb?#{search_string}'>Link to this search</a><br>"
puts '<a href="/hex/">Search Again?</a>'
if output_format =~ /html_card/
  puts ''
elsif output_format =~ /html/
  puts '<div class="CSSTableGenerator" > '
  puts '<table>'
else
  puts '<xmp>'
end
#puts Hex::Card.dump_html_table_header
puts Hex::Card.send("dump_#{output_format}_header")
foo.cards.sort {|a, b| a.card_number.to_i <=> b.card_number.to_i}.each do |card|
  puts card.send("to_#{output_format}")
end

if output_format =~ /html_card/
  puts ''
elsif output_format =~ /html/
  puts '</table>'
else
  puts '</xmp>'
end

puts "<a href='/hex/search.rb?#{search_string}'>Link to this search</a><br>"
puts '<a href="/hex/">Search Again?</a>'

puts "</body>"
puts "</html>"
#binding.pry
end
