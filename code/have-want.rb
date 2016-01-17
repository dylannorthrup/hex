#!/usr/bin/env ruby
#
# Test out ERB templating

# Print out HTTP headers
puts "Content-type: text/plain"
puts ""

require 'pry'
require 'open-uri'

# Grab all card prices and figure out exchange rate between Gold and Plat
price_file = "/home/docxstudios/web/hex/all_prices.txt"
prices = Hash.new
File.readlines(price_file).each do |line|
  #next unless line =~ /^\d+ gold per plat \[(\d+)p - (\d+)g\]  => (.*)$/
  next unless line =~ /^(.*) \.\.\. (\d+) PLATINUM.* \.\.\. (\d+) GOLD/
  card_name = $1
  plat_price = $2
  gold_price = $3
  card_name.gsub!(/\s*$/, '')  # Get rid of any trailing spaces
#  puts "#{card_name} = #{plat_price}p and #{gold_price}g"
  prices[card_name] = Hash.new
  prices[card_name]['plat'] = plat_price
  prices[card_name]['gold'] = gold_price
end

# Figure out exchange rates between Gold and Plat
exchange_file = "/home/docxstudios/web/hex/sorted_gold_plat_comparisons.txt"
rates = Array.new
File.readlines(exchange_file).each do |line|
  next unless line =~ /^(\d+) gold per plat.*Set .* Booster Pack\s*$/
  rates << $1
end

prices.keys.each do |p|
#  puts "'#{p}' = #{prices[p]['plat']}p and #{prices[p]['gold']}g"
end

sum = 0
rates.each do |rate|
  sum += rate.to_i
end
avg_exch = (sum / rates.size).round
puts "INFO: Using #{avg_exch} gold to 1 plat as conversion rate based on Booster Pack prices"
puts ""

count_files = [ '/home/docxstudios/web/hex/aom_counts.txt', '/home/docxstudios/web/hex/pve_counts.txt', '/home/docxstudios/web/hex/sd_counts.txt', '/home/docxstudios/web/hex/sof_counts.txt' ]

needed = Array.new
surplus = Array.new

count_files.each do |count_file|
  raw_data = open(count_file).read

  # Go through each row.  If we don't have at least four, add the card info to the needed array
  raw_data.lines.each do |row|
    next unless row =~ /^"([^"]+)",(\d+),"([^"]+)","([^"]+)"$/
    name = $1
    count = $2.to_i
    rarity = $3
    shard = $4
    # Shortcut here if we're simply not interested in the cards
    next unless rarity =~ /Legendary|Rare|Epic/
    if rarity == /Epic/ then
      key = name + " AA"
    else
      key = name
    end
    key.gsub!(/,/, '')
    price = "NO DATA"
    gprice = "NO DATA"
    if not prices[key].nil? then
      price = prices[key]['plat']
      gprice  = prices[key]['gold']
    end
    # Skip cards we don't care about
    if count > 4
      value = "#{'%-9.9s' % rarity} - #{'%-40.40s' % name} Have #{count - 4} for trade - P: #{'%7.7s' % price} <=> G: #{'%7.7s' % gprice}"
      surplus << value
    end
    # And skip Epic (aka 'AA' cards for wants)
    next if rarity =~ /Epic/
    if count < 4
      pi = price.to_i; gi = gprice.to_i
      # Put indicator here which is the better value based on exchange rate: gold or plat
      if (pi * avg_exch) < gi or gi == 0 then
        # If plat * avg_exch < gold price, then buy using plat
        value = "#{'%-9.9s' % rarity} - #{'%-40.40s' % name} Want #{4 - count} - P:> #{'%7.7s' % price} <=> G:  #{'%7.7s' % gprice}"
      elsif (pi * avg_exch) > gi or pi == 0 then
        # If plat * avg_exch > gold price, then buy using gold
        value = "#{'%-9.9s' % rarity} - #{'%-40.40s' % name} Want #{4 - count} - P:  #{'%7.7s' % price} <=> G:> #{'%7.7s' % gprice}"
      else
        # This should not be hit (since we squished everything into 'avg_exch' and went away from high_exch/low_exch)
        # But leaving here in case we want to go back to this sometime
        # Otherwise, they're both equally good values
        value = "#{'%-9.9s' % rarity} - #{'%-40.40s' % name} Want #{4 - count} - P:> #{'%7.7s' % price} <=> G:> #{'%7.7s' % gprice}"
      end
      needed << value
    end
  end
end

puts "========== WANTS ===================================================================="
needed.sort.each do |row|
  puts row
end

puts "\n\n========== HAVES ===================================================="
surplus.sort.each do |row|
  puts row
end

