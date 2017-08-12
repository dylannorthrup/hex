#!/usr/bin/env ruby
#
# Grab auction messages and put them into their own table

require 'fileutils'
require 'mysql'
require 'json'
require 'pry'

def get_db_con
  pw = File.open("/home/docxstudios/hex_tcg.pw").read.chomp
  con = Mysql.new 'mysql.doc-x.net', 'hex_tcg', pw, 'hex_tcg'
end

@rcon = get_db_con # Used for reading data from the database
@wcon = get_db_con # Used for writing back to the database

@sentinel_file = '/home/docxstudios/web/hex/code/auction_dump_active'
@cnter = 1
@auction_dump_log = "/home/docxstudios/web/hex/code/adump.log"
@log_fh = File.open(@auction_dump_log, "w")
@tdids_to_update = {}

trap "SIGINT" do
  puts "Deleting sentinel file"
  File.delete(@sentinel_file)
  puts "Exiting"
  exit 130
end

@deal_pct = 0.6

# Utility print debug message
@DEBUG = false
def pdebug(msg=nil)
  return if msg.nil?
  return unless @DEBUG
  @log_fh.puts "DEBUG: #{msg}"
  puts "DEBUG: #{msg}"
end

# Do this so we can rely on the cached price data
card_price_data = File.open("/home/docxstudios/web/hex/all_prices_json.txt").read
@cpd = JSON.parse(card_price_data)
@cards = Hash.new
@cpd['cards'].each do |c|
  @cards[c['uuid']] = c
end

File.open("/home/docxstudios/web/hex/uuid_map.txt").read.each_line do |line|
  (u, n) = line.split(/  /)
#  pdebug "testing for #{u} and #{n}"
  if @cards[u].nil?
#    pdebug "Adding #{n} with uuid #{u} to cards"
    @cards[u] = Hash.new
    @cards[u]['name'] = n
    @cards[u]['rarity'] = "Bogus"
  end
end


### METHODS

# This is a dumb utility method whose only purpose is to print out numbers counting up from 0-9
def print_cnter
  print "#{@cntr}"
  @cntr += 1
  if @cntr > 9 then
    @cntr = 0
  end
end

def uuid_to_name (uuid=nil) 
  return "" if uuid.nil?
  return "Unknown_#{uuid}" if @cards[uuid].nil?
  return @cards[uuid]['name']
end

def uuid_to_rarity (uuid=nil) 
  return "" if uuid.nil?
  return "Unknown_#{uuid}" if @cards[uuid].nil?
  return @cards[uuid]['rarity']
end

def is_deal(auc=nil, card=nil)
  return if auc.nil?
  return if card.nil?
  # Not interested in Common or Uncommon cards
  return if card['rarity'] == "Common" and card['type'] == "Card"
  return if card['rarity'] == "Uncommon" and card['type'] == "Card"
  deal = false
  deal_txt = "DEAL on \"#{card['name']}\" "
  # If it's this much below normal, SUCH A DEAL
  
  if (auc['GoldBuyout'].to_i > 0 && auc['GoldBuyout'].to_i < card['GOLD']['avg'].to_i * @deal_pct) then
    deal = true
    deal_txt += "GOLD Buyout of #{auc['GoldBuyout']} < #{card['GOLD']['avg'].to_i} * #{@deal_pct} "
  end
  if (auc['PlatBuyout'].to_i > 0 && auc['PlatBuyout'].to_i < card['PLATINUM']['avg'].to_i * @deal_pct) then
    deal = true
    deal_txt += "PLAT Buyout of #{auc['PlatBuyout']} < #{card['PLATINUM']['avg'].to_i} * #{@deal_pct} "
  end

  if deal then
    puts "#{deal_txt}\n";
  end
end

def update_ah_data_query(e=nil)
  return if e.nil?
  name = uuid_to_name(e['Item'])
  rarity = uuid_to_rarity(e['Item'])
  # Determine currency
  currency = "GOLD"
  action = e['Action']
  price = 0
  # If action is close, then we're looking at bids
  if action == "CLOSE" then
    if e['GoldBid'].to_i == 0 then
      currency = "PLATINUM"
      price = e['PlatBid'].to_s
    else
      currency = "GOLD"
      price = e['GoldBid'].to_s
    end
  else  # We're dealing with a buyout
    if e['GoldBuyout'].to_i == 0 then
      currency = "PLATINUM"
      price = e['PlatBuyout'].to_s
    else
      currency = "GOLD"
      price = e['GoldBuyout'].to_s
    end
  end
  rarity = uuid_to_rarity(e['Item'])
  query = "INSERT INTO ah_data values ('#{Mysql.escape_string name}', '#{Mysql.escape_string currency}', '#{Mysql.escape_string price}', '#{Time.now}', '#{Mysql.escape_string rarity}', '#{Mysql.escape_string e['Item']}')"
  return query
end

def mark_tournament_data_updated(tdid=nil)
  return if tdid.nil?
  if tdid == "go" then
    @tdids_to_update.each_pair do |tdid, num|
      query = "UPDATE tournament_data set aah_processed = 1 where id = '#{Mysql.escape_string tdid}'"
      pdebug "=== updating tournament_data table"
      pdebug "#{query}"
      start = Time.now
      @wcon.query(query);
      finish = Time.now
      diff = finish - start
      pdebug "=== sql update complete (#{diff} seconds)"
    end
  else
    pdebug "Adding #{tdid} to update hash"
    if @tdids_to_update[tdid].nil? then
      @tdids_to_update[tdid] = 0
    end
    @tdids_to_update[tdid] += 1
    return
  end
end

def handle_results(results=nil) 
  return if results.nil?
  results.each do |row|
    data = row[0]
    time = row[1]
    tdid = row[2]
    unless data.match(/"MessageType": "Auction"/) then
      pdebug "NON AUCTION LINE: Updating row for #{time}"
      mark_tournament_data_updated(tdid)
      next
    end
    time.gsub!(/ /, '_')
    pdebug "Working on Auction line from #{time}"
    begin
      mjson = JSON.parse(data)
    rescue JSON::ParserError, Encoding::InvalidByteSequenceError => e
      puts "Had problem parsing thing from #{time}: #{e}"
      next
    end
    ah_data_query = nil
    events = mjson['Events']
    events.each do |e|
      pdebug "working on event #{e}"
      if e['Item'] == "00000000-0000-0000-0000-000000000000" 
        next unless e['Action'] == "SOLD" or e['Action'] == "CLOSE"
      else
        if @cards[e['Item']].nil?
          #binding.pry
          pdebug "Could not find information for event #{e}"
          next
        end
      #pdebug "Processing #{action} action"
        e2 = update_event_details(e)
        # Set up the query based on the Action
        name = uuid_to_name(e['Item'])
        rarity = uuid_to_rarity(e['Item'])
      end
      action = e['Action']
      # For POST, add the item to the DB
      if action == "POST" 
        #binding.pry
        query = "REPLACE INTO active_ah values ('#{Mysql.escape_string e['AuctionId']}', '#{Mysql.escape_string e['Actor']}', '#{Mysql.escape_string e['Action']}', '#{Mysql.escape_string e['PlatBid']}', '#{Mysql.escape_string e['PlatBuyout']}', '#{Mysql.escape_string e['GoldBid']}', '#{Mysql.escape_string e['GoldBuyout']}', '#{Mysql.escape_string e['Item']}', '#{Mysql.escape_string name}', '#{Time.now}', '#{Mysql.escape_string rarity}', true)"
      # For CLOSE, look up the auction info and set the row as inactive
      elsif e['Action'] == "CLOSE" 
        e = update_event_details(e)
        if e.nil?
          pdebug "No event info was found for this line. Marking tournament_data line as processed."
          mark_tournament_data_updated(tdid)
          next
        end
        query = "UPDATE active_ah SET last_action='#{Mysql.escape_string e['Action']}', active=false WHERE auctionid = '#{Mysql.escape_string e['AuctionId']}'"
        ah_data_query = update_ah_data_query(e)
      # For BUYOUT, set the row as inactive
      elsif e['Action'] == "BUYOUT"
        #query = "DELETE FROM active_ah WHERE auctionid = '#{Mysql.escape_string e['AuctionId']}'"
        query = "UPDATE active_ah SET last_action='#{Mysql.escape_string e['Action']}', active=false WHERE auctionid = '#{Mysql.escape_string e['AuctionId']}'"
        ah_data_query = update_ah_data_query(e)
      # For SOLD we need to get the GUID from the table and update the event object
      elsif e['Action'] == "SOLD"
        pdebug "$$$ Doing SOLD action"
        query = "UPDATE active_ah SET last_action='#{Mysql.escape_string e['Action']}', active=false WHERE auctionid = '#{Mysql.escape_string e['AuctionId']}'"
        e = update_event_details(e)
        # No event info was found, so let's at least mark this tournament_data line as processed.
        if e.nil?
          pdebug "No event info was found for this line. Marking tournament_data line as processed."
          mark_tournament_data_updated(tdid)
          next
        end
        ah_data_query = update_ah_data_query(e)
 #       pdebug "$$$ set ah_data_query to #{ah_data_query}"
        name = uuid_to_name(e['Item'])
        rarity = uuid_to_rarity(e['Item'])
      # And for BID, update the bid 
      elsif e['Action'] == "BID" 
        query = "UPDATE active_ah set last_action='BID', platbid='#{Mysql.escape_string e['PlatBid']}', goldbid='#{Mysql.escape_string e['GoldBid']}' WHERE auctionid = '#{e['AuctionId']}'";
      else
        pdebug "UNKNOWN Action was #{e['Action']}: #{e}"
      end
      pdebug "#{e['Action']} ACTION for #{name}"
      pdebug "=== sql query: #{query}"
      @wcon.query(query)
      pdebug "=== sql query complete"
      # And update the tournament_data db so we don't re-process old messages
      mark_tournament_data_updated(tdid)
      # If we don't have a ah_data update, move on to the next line
      if ah_data_query.nil? then
        if e['Action'] == "CLOSE" or e['Action'] == "BUYOUT" or e['Action'] == "SOLD"
          pdebug "!!!! ZOMGZ!!! We should have an ah_data_query for action #{e['Action']} and we don't. Investigate"
#        else
#          pdebug "skipping because it was nil"
        end
        next
      end
      pdebug "*** AH_DATA_QUERY: #{ah_data_query}"
      @wcon.query(ah_data_query);
      ah_data_query = nil
    end
#      pdebug ":"
  end
#  pdebug ";"
end

def update_event_details(event=nil)
  return if event.nil?
  auctionid = event['AuctionId']
  pdebug "Getting auction details for auction id #{auctionid}"
  detail_query = "SELECT item, platbid, platbuyout, goldbid, goldbuyout, name, rarity FROM active_ah WHERE auctionid='#{Mysql.escape_string event['AuctionId']}'"
#  pdebug detail_query 
  detail_result = @rcon.query(detail_query)
  if detail_result.num_rows == 0
    pdebug "Auction #{auctionid} has no information"
    return nil
  end
  detail_ary = detail_result.fetch_row
  event['Item']       = detail_ary[0]
  event['PlatBid']    = detail_ary[1]
  event['PlatBuyout'] = detail_ary[2]
  event['GoldBid']    = detail_ary[3]
  event['GoldBuyout'] = detail_ary[4]
  event['Name']       = detail_ary[5]
  event['Rarity']     = detail_ary[6]
  return event  
end

### END METHODS

if File.exist?(@sentinel_file)
  file_age_in_days = (Time.now - File.stat(@sentinel_file).mtime).to_i / 86400.0
  if file_age_in_days > 2 then
    puts "Sentinel file #{@sentinel_file} is older than 2 days. Might want to take a look at why"
  end
  exit
end

FileUtils.touch(@sentinel_file)

@start = 0
@set = 100

query = "SELECT COUNT(*) FROM tournament_data WHERE insert_time > NOW() - INTERVAL 2 DAY AND aah_processed IS NULL"
result = @rcon.query(query)
res_ary = result.fetch_row
num_rows = res_ary[0].to_i

while @start < num_rows do
  @cntr = 0
  pdebug "Working on #{@start} out of #{num_rows}"
  query = "SELECT td, insert_time, id FROM tournament_data WHERE insert_time > NOW() - INTERVAL 2 DAY AND aah_processed IS NULL ORDER BY insert_time ASC limit #{@set} offset #{@start}"
  pdebug "Making query: #{query}"
  results = @rcon.query(query)
  pdebug "Handling results"
  handle_results(results)
  @start += @set
end

mark_tournament_data_updated("go")
# Finally, get rid of all of the data older than 2 days
query = "DELETE FROM active_ah WHERE createtime < date_sub(NOW(), interval 2 day)"
result = @wcon.query(query)

@rcon.close
@wcon.close
@log_fh.close
File.delete(@sentinel_file)
