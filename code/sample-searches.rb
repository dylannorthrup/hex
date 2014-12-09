#!/usr/bin/env ruby
#
# Print up tables of sample searches based on card type, sub-type, shards, thresholds, etc.

require 'cgi'

@search_url = 'http://doc-x.net/hex/search.rb?'
@num_cols = 5

# Helper for printing out search links
def search_link(attr, value, content)
  string = "<a href='#{@search_url}#{attr.downcase}=#{value.downcase}'>#{content}</a>"
end

# Helper for printing out search links for ATK/Health searches
def search_ah_link(atk, health, content)
  string = "<a href='#{@search_url}type=troop&atk=#{atk}&health=#{health}'>#{content}</a>"
end

# Print out HTTP headers
puts "Content-type: text/html"
puts ""

require "pry"
$: << "/home/docxstudios/web/hex/code"
require "Hex"
foo = Hex::Collection.new
con = foo.get_db_con
#search = "rarity regexp 'Legendary' OR rarity regexp 'Rare'"
foo.load_collection(con)

types = Hash.new(0)
sub_types = Hash.new(0)

traits = %w< Set_ID Type Cost Rarity Color Sub_Type Restriction Socket_Count Faction ATK Health Threshold_Color Threshold_Number >
#traits = %w< ATK Health >
trait_list = Hash.new
traits.each do |trait|
  t_ary = foo.card_trait_list(trait, '\|?,? ')
  trait_list[trait] = t_ary
end

count = 0

puts "<head>"
#puts '<link rel="stylesheet" type="text/css" href="/hex/tables.css">'
puts "</head>"
puts '<h1>Example Searches</h1>'
puts '<table style="table-layout:fixed; overflow:hidden; white-space:nowrap;">'
trait_list.each_pair do |trait, t_ary|
  next if trait =~ /ATK|Health/
  count += 1
  if count % @num_cols == 1
    puts "<tr>"
  end
  # Have sub_type span multiple rows since it's so large
  if trait =~ /Sub_Type/
    puts "<td valign=top rowspan=5><h2>#{trait.gsub(/_/, ' ')}</h2>"
  else
    puts "<td valign=top><h2>#{trait.gsub(/_/, ' ')}</h2>"
  end
  puts '<ul>'
#  puts "#{t_ary.size} items"
  t_ary.each do |t|
    puts "  <li> #{search_link(trait, t, t)}"
  end
  puts '</ul></td>'
  if count % @num_cols == 0
    puts "</tr>"
  end
end
# To close out uneven tables if necessary
if count % @num_cols == 1
  puts "</tr>"
end

# Special Handling for ATK and Health
puts "<tr><td valign=top colspan=2>"
puts "<h2>ATK</h2>"
puts '<ul>'
atk_ary = trait_list['ATK']
health_ary = trait_list['Health']
atk_ary.each do |a|
  print "  <li> #{search_link('ATK', a, a)}"
  health_ary.each do |h|
    link = search_ah_link(a, h, "#{a}/#{h}")
    print " - #{link}"
  end
  puts
end
puts '</ul></td>'
puts "<td valign=top colspan=2><h2>Health</h2>"
puts '<ul>'
health_ary.each do |h|
  print "  <li> #{search_link('Health', h, h)}"
  atk_ary.each do |a|
    link = search_ah_link(a, h, "#{a}/#{h}")
    print " - #{link}"
  end
  puts
end
puts '</ul></td></tr>'
puts '</table>'

#binding.pry
puts "</body>\n</html>"
