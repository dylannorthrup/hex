#!/usr/bin/env ruby
#
# Figure out which card I should sell next

puts "Content-type: text/plain"
puts ""
puts "IT HAS BEGUN [#{Time.now}]"

price_file='/home/docxstudios/web/hex/all_prices_with_uuids.txt';
count_file='/home/docxstudios/web/hex/code/collection.out';
@cards_to_keep = 4
@how_many_to_show = 10

card_info = Hash.new

# Get prices
puts "Getting prices [#{Time.now}]"
File.open(price_file).each_line do |line|
  bits = line.split(/ \.\.\. /)
  uuid = bits[1]
  
  card_info[uuid] = Hash.new
  card_info[uuid]['name'] = bits[0]
  card_info[uuid]['plat'] = bits[2].gsub!(/ *PLATINUM.*/, '').to_i
  card_info[uuid]['gold'] = bits[3].gsub!(/ *GOLD.*/, '').to_i
  card_info[uuid]['gtot'] = 0
  card_info[uuid]['ptot'] = 0
end

# Add counts
puts "Getting counts [#{Time.now}]"
File.open(count_file).each_line do |line|
  bits = line.split(/ : /)
  uuid = bits[0]
  count = bits[1].to_i - @cards_to_keep
  next if card_info[bits[0]].nil?
  card_info[uuid]['count'] = count
  card_info[uuid]['gtot'] = card_info[uuid]['gold'] * count
  card_info[uuid]['ptot'] = card_info[uuid]['plat'] * count
end

#binding.pry

puts "=== TOP Gold Holdings"
card_info.sort_by{|_key, value| value['gtot'] }.reverse.first(@how_many_to_show).each do |thing|
  name = "%-30.30s" % thing[1]['name']
  puts "#{name} - #{"%3.3s" % thing[1]['count']} extra to sell @ #{thing[1]['gold']}g each [#{thing[1]['gtot']}g total]"
end
puts "=== TOP Plat Holdings"
card_info.sort_by{|_key, value| value['ptot'] }.reverse.first(@how_many_to_show).each do |thing|
  name = "%-30.30s" % thing[1]['name']
  puts "#{name} - #{"%3.3s" % thing[1]['count']} extra to sell @ #{thing[1]['plat']}p each [#{thing[1]['ptot']}p total]"
end


#merge_price_and_count() {
#  cat collection.out | while read line; do 
##    set -x
#    UUID=$(echo $line | awk -F: '{print $1}')
#    COUNT=$(echo $line | awk -F: '{print $NF}' | sed -e 's/^ *//')
#    STUFF=$(grep ${UUID} ${PRICE_FILE} | sed -e 's/ \.\.\. /=/g; s/\[[0-9]* auctions\]//g; s/ *PLATINUM *//g; s/ *GOLD *//g;')
##    echo "$COUNT = $STUFF" 
#    echo "${COUNT}=${STUFF}" | awk -F\= '{g = ($1-20) * $5; if( g > 0 ) print g, $2, "[", $5, "each ]"}' 
##    echo "${COUNT}=${STUFF}" | awk -F\= '{print $1, $2, $3, $4, $5}'
##    set +x
##sleep 1
##    echo $STUFF
#  done
#}
#
#merge_price_and_count
#
#exit
#
#echo === TOP GOLD HOLDINGS
##sed -e 's/GOLD //g' price_and_count_data.out | awk -F\- '{g = ($1-20) * $4; if( g > 0 ) print g, $2, "[" $4, "each]"}' | sort -rn | head -5
#awk -F\- '{g = ($1-20) * $4; if( g > 0 ) print g, $2, "[" $4, "each ]"}' price_and_count_data.out | sort -rn | head -5
#echo 
#echo === TOP PLAT HOLDINGS
#awk -F\- '{g = ($1-20) * $3; if( g > 0 ) print g, $2, "[" $3 "each ]"}' price_and_count_data.out | sort -rn | head -5
#sed -e 's/PLATINUM //g' price_and_count_data.out | awk -F\- '{g = ($1-20) * $3; if( g > 0 ) print g, $2, "[" $3, "each]"}' | sort -rn | head -5
