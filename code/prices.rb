#!/usr/bin/env ruby
#
# get prices for rare and legendary cards for both gold and platinum from Hex price data

$: << "/home/docxstudios/web/hex/code"
require 'mysql'
require 'Hex'
require 'moving_average'
#require 'pry'

# Some (reasonably) global variables
@cutoff_time_in_hours = 336   # Price data older than this will be skipped. 336 hours = 14 days
@fname = "AH_Sold_Cards.csv"
@price_data = Hash.new
@card_names = Hash.new
@output_type  = 'CSV'   # The other option currently is 'HTML'. Others may happen down the road
@content_types = {
  'CSV'   => 'text/plain',    # Comma Separated Variables
  'PDCSV' => 'text/plain',    # Price Data Comma Separated Variables
  'PSV'   => 'text/plain',    # Pipe Separated Variables
  'UUIDPSV'   => 'text/plain',    # Pipe Separated Variables with UUID
  'HTML'  => 'text/html',     # HTML Tables
  'JSON'  => 'application/json',    # JSON
}
@output_detail = 'detailed'
@name_filter = '.*'
@exclude_filter = nil

@card_closing_bits = {
  'CSV'   => {
    'brief'     => '',
    'detailed'  => '',
  },
  'PDCSV'   => {
    'brief'     => '',
    'detailed'  => '',
  },
  'PSV'   => {
    'brief'     => '',
    'detailed'  => '',
  },
  'UUIDPSV'   => {
    'brief'     => '',
    'detailed'  => '',
  },
  'JSON'   => {
    'brief'     => 'puts "{\"bogus\": 1}\n]}"',
    'detailed'  => 'puts "{\"bogus\": 1}\n]}"',
  },
  'HTML'   => {
    'brief'     => 'puts "</table></div>"',
    'detailed'  => 'puts "</table></div>"',
  }
}
@card_field_descriptors = {
  'CSV'   => {
    'brief'     => 'puts "Name,Avg_price,Currency,# of auctions,Avg_price,Currency,# of auctions"',
    'detailed'  => 'puts "\"Name\",\"Rarity\",\"Currency\",Weighted Average Price,# of Auctions,Average Price,Min price,Lower Quartile,Median,Upper Quartile,Maximum Price,\"Excluded Prices\",\"Currency\",Weighted Average Price,# of Auctions,Average Price,Min price,Lower Quartile,Median,Upper Quartile,Maximum Price,\"Excluded Prices\",UUID"'
  },
  'PDCSV'   => {
    'brief'     => '',
    'detailed'  => 'puts "Average Price (Plat), Average Price (Gold),\"Name\"'
  },
  'PSV'   => {
    'brief'     => 'puts "Name ... Avg_price Currency [# of auctions] ... Avg_price Currency [# of auctions]"',
    'detailed'  => 'puts "Name|Rarity|Currency|Weighted Average Price|# of Auctions|Average Price|Min price|Lower Quartile|Median|Upper Quartile|Maximum Price|\"Excluded Prices\"|Currency|Weighted Average Price|# of Auctions|Average Price|Min price|Lower Quartile|Median|Upper Quartile|Maximum Price|\"Excluded Prices\""'
  },
  'UUIDPSV'   => {
    'brief'     => 'puts "Name ... UUID ... Avg_price Currency [# of auctions] ... Avg_price Currency [# of auctions]"',
    'detailed'  => 'puts "Name|UUID|Rarity|Currency|Weighted Average Price|# of Auctions|Average Price|Min price|Lower Quartile|Median|Upper Quartile|Maximum Price|\"Excluded Prices\"|Currency|Weighted Average Price|# of Auctions|Average Price|Min price|Lower Quartile|Median|Upper Quartile|Maximum Price|\"Excluded Prices\""'
  },
  'JSON'   => {
    'brief'     => 'puts "{\n\"cards\": [\n"',
    'detailed'  => 'puts "{\n\"cards\": [\n"',
  },
  'HTML'  => {
    'brief'     => 'puts "<div class=\'CSSTableGenerator\'><table><tr><th>Card Name</th><th>Currency</th><th>Avg w/o outliers</th><th>Number of auctions</th><th>Average with outliers</th><th>Min price</th><th>1st quartile price</th><th>Median price</th><th>3rd quartile price</th><th>Max price</th><th>Excluded values</th><th>Currency</th><th>Avg w/o outliers</th><th>Number of auctions</th><th>Average with outliers</th><th>Min price</th><th>1st quartile price</th><th>Median price</th><th>3rd quartile price</th><th>Max price</th><th>Excluded values</th></tr>"',
    'detailed'  => 'puts "<div class=\'CSSTableGenerator\'><table><tr><th>Card Name</th><th>Currency</th><th>Avg w/o outliers</th><th>Number of auctions</th><th>Average with outliers</th><th>Min price</th><th>1st quartile price</th><th>Median price</th><th>3rd quartile price</th><th>Max price</th><th>Excluded values</th><th>Currency</th><th>Avg w/o outliers</th><th>Number of auctions</th><th>Average with outliers</th><th>Min price</th><th>1st quartile price</th><th>Median price</th><th>3rd quartile price</th><th>Max price</th><th>Excluded values</th></tr>"',
  }
}
@card_init_string = {
  'CSV'   => {
    'brief'     => 'str = "#{name.gsub(/^\'/, \'\').gsub(/\' \[.*\]$/, \'\')}"',
    'detailed'  => 'str = "\"#{name.gsub(/^\'/, \'\').gsub(/\' \[(.*)\]$/, "\",\"\\\1\"")}"',
  },
  'PDCSV'   => {
    'brief'     => 'str = ""',
    'detailed'  => 'str = ""',
  },
  'PSV'   => {
    'brief'     => 'str = "#{name.gsub(/^\'/, \'\').gsub(/\' \[.*\]$/, \'\')}"',
    'detailed'  => 'str = "#{name.gsub(/^\'/, \'\').gsub(/\' \[(.*)\]$/, "|\\\1")}"',
  },
  'UUIDPSV'   => {
    'brief'     => 'str = "#{name.gsub(/^\'/, \'\').gsub(/\' \[.*\]$/, \'\')} ... #{uuid}"',
    'detailed'  => 'str = "#{name.gsub(/^\'/, \'\').gsub(/\' \[(.*)\]$/, "|\\\1")}|#{uuid}"',
  },
  'JSON'   => {
    'brief'     => 'str = "{\"name\": \"#{name.gsub(/^\'/, \'\').gsub(/\' \[.*\]$/, \'\')}\", "',
    'detailed'  => 'str = "{ \"name\": \"#{name.gsub(/^\'/, \'\').gsub(/\' \[(.*)\]$/, "\",\n  \"rarity\": \"\\\1")}\",\n"',
  },
  'HTML'  => {
    'brief'     => 'str = "<tr><td>#{name.gsub(/^\'/, \'\').gsub(/\' \[.*\]$/, \'\')}</td>"',
    'detailed'  => 'str = "<tr><td>#{name}</td>"',
  }
}
@card_details_string = {
  'CSV'   => {
    'brief'     => 'str << ",#{avg},\"#{currency}\",#{sample_size}"',
    'detailed'  => 'str << ",\"#{currency}\",#{avg},#{sample_size},#{true_avg},#{min},#{lq},#{med},#{uq},#{max},\"#{excl}\""',
  },
  'PDCSV'   => {
    'brief'     => 'str << "#{avg},"',
    'detailed'  => 'str << "#{avg},"',
  },
  'PSV'   => {
    'brief'     => 'str << " ... #{avg} #{currency} [#{sample_size} auctions]"',
    'detailed'  => 'str << "|#{currency}|#{avg}|#{sample_size}|#{true_avg}|#{min}|#{lq}|#{med}|#{uq}|#{max}|#{excl}"',
  },
  'UUIDPSV'   => {
    'brief'     => 'str << " ... #{avg} #{currency} [#{sample_size} auctions]"',
    'detailed'  => 'str << "|#{currency}|#{avg}|#{sample_size}|#{true_avg}|#{min}|#{lq}|#{med}|#{uq}|#{max}|#{excl}"',
  },
  'JSON'   => {
    'brief'     => 'str << "{\"#{currency}\":\n\t{\"avg\": #{avg},\n\t\"sample_size\": #{sample_size}\n},"',
    'detailed'  => 'str << "  \"#{currency}\": {
    \"avg\": #{avg},
    \"sample_size\": #{sample_size},
    \"true_avg\": #{true_avg},
    \"min\": #{min},
    \"lq\": #{lq},
    \"med\": #{med},
    \"uq\": #{uq},
    \"max\": #{max},
    \"excl\": \"#{excl}\"
  },\n"',
  },
  'HTML'  => {
    'brief'     => 'str << "<td>#{currency}</td><td>#{avg}</td><td>#{sample_size}</td><td>#{true_avg}</td><td>#{min}</td><td>#{lq}</td><td>#{med}</td><td>#{uq}</td><td>#{max}</td><td>#{excl}</td>"',
    'detailed'  => 'str << "<td>#{currency}</td><td>#{avg}</td><td>#{sample_size}</td><td>#{true_avg}</td><td>#{min}</td><td>#{lq}</td><td>#{med}</td><td>#{uq}</td><td>#{max}</td><td>#{excl}</td>"',
  }
}
@card_closing_string = {
  'CSV'   => {
    'brief'     => '',
    'detailed'  => 'str << ",#{uuid}"',
  },
  'PDCSV'   => {
    'brief'     => 'str << "\"#{name.gsub(/^\'/, \'\').gsub(/\' \[(.*)\]$/, "\"")}"',
    'detailed'  => 'str << "\"#{name.gsub(/^\'/, \'\').gsub(/\' \[(.*)\]$/, "\"")}"',
  },
  'PSV'   => {
    'brief'     => '',
    'detailed'  => '',
  },
  'UUIDPSV'   => {
    'brief'     => '',
    'detailed'  => '',
  },
  'JSON'   => {
    'brief'     => 'str << "  \"uuid\": \"#{uuid}\"\n},\n"',
    'detailed'  => 'str << "  \"uuid\": \"#{uuid}\"\n},\n"',
  },
  'HTML'  => {
    'brief'     => '',
    'detailed'  => '',
  }
}

# Read in AH data from CSV file
def read_file(fname=nil)
  return if fname.nil?
  # Array we use to store entries
  lines = Array.new
  # Deal with DOS line endings by reading in file, then manually splitting on DOS line ending
  File.open(fname).each_line do |line|
    lines = line.split(/\r\n?/).map(&:chomp)
  end
  return lines
end

# Read in names from database
def read_names_from_db(sqlcon=nil, filter='')
  return if sqlcon.nil?
  names = Array.new
  query = "SELECT c.name, c.rarity FROM cards c WHERE c.rarity NOT LIKE 'Epic' #{filter}"
  results = sqlcon.query(query)
  results.each do |row|
    name = "'#{row[0]}' [#{row[1]}]"
    name.gsub!(/,/, '')
#    puts name
    names << name
  end
  build_card_names_hash(names)
end

# Read in AH data from database
# This is farmed out to 'read_db_with_uuids' as we've got the logic there and are updating everything
# to use UUIDs now.  One day I may clean this up, but too busy today.
def read_db(sqlcon=nil, filter='')
  return read_db_with_uuids(sqlcon, filter)
end

def add_no_ah_data_uuid_lines(results)
  return if results.nil?
#  binding.pry
  return_lines = Array.new
  ah_to_card_rarity = {
    "Equipment" => 0,
    "Unknown"   => 1,
    "Common"    => 2,
    "Uncommon"  => 3,
    "Rare"      => 4,
    "Epic"      => 5,
    "Legendary" => 6,
  }
  results.each do |row|
    name = row[0]
    rarity = row[1]
    if rarity == 'Epic' then
      name += " AA"
    end
    uuid = row[2]
    sale_date = Time.now.strftime("%Y-%m-%d")
    gline = "'#{name}' [#{rarity}],GOLD,0,#{sale_date},#{ah_to_card_rarity[rarity]},#{uuid}"
    pline = "'#{name}' [#{rarity}],PLATINUM,0,#{sale_date},#{ah_to_card_rarity[rarity]},#{uuid}"
    #puts line
    return_lines << gline
    return_lines << pline
  end
  return return_lines
end

def add_uuid_lines(results)
  return_lines = Array.new
  results.each do |row|
    name = row[0]
    rarity = row[3]
    if rarity == 'Epic' then
      name += " AA"
    end
    uuid = row[6]
    line = "'#{name}' [#{row[3]}],#{row[1]},#{row[2]},#{row[4]},#{row[5]},#{uuid}"
    #puts line
    return_lines << line
  end
  return return_lines
end

# Read in AH data from database including AAs and UUIDs
def read_db_with_uuids(sqlcon=nil, filter='')
  return if sqlcon.nil?
  lines = Array.new
  # Select from database to get all bits. Get non-Epic stuff first
  query = "SELECT ah.name, ah.currency, ah.price, c.rarity, ah.sale_date, ah.rarity, c.uuid FROM ah_data ah, cards c WHERE c.parsed_name = ah.name AND c.rarity NOT LIKE 'Epic' AND c.type NOT LIKE 'Champion' AND ah.rarity NOT LIKE '5' #{filter}"
  results = sqlcon.query(query)
  lines = lines + add_uuid_lines(results)
  # Now, do the same thing, but for epic cards and prices
  query = "SELECT ah.name, ah.currency, ah.price, c.rarity, ah.sale_date, ah.rarity, c.uuid FROM ah_data ah, cards c WHERE c.parsed_name = ah.name AND c.rarity LIKE 'Epic' AND c.type NOT LIKE 'Champion' AND ah.rarity LIKE '5' #{filter}"
  results = sqlcon.query(query)
  lines = lines + add_uuid_lines(results)
  # Now, get all the non-AA cards and equipment that don't have any auction information
  query = "SELECT c.parsed_name, c.rarity, c.uuid FROM cards c WHERE c.name IS NOT NULL AND c.parsed_name NOT IN (SELECT distinct(name) FROM ah_data WHERE rarity NOT LIKE '5') AND type not like 'Champion' AND rarity NOT LIKE 'Epic' AND c.set_id NOT LIKE '%AI' #{filter}"
  results = sqlcon.query(query)
  lines = lines + add_no_ah_data_uuid_lines(results)
  # Finally, get all of the AA (Epic) cards that don't have any auction info
  query = "SELECT c.parsed_name, c.rarity, c.uuid FROM cards c WHERE c.name IS NOT NULL AND c.parsed_name NOT IN (SELECT distinct(name) FROM ah_data WHERE rarity LIKE '5') AND rarity LIKE 'Epic' AND c.set_id NOT LIKE '%AI' #{filter}"
  results = sqlcon.query(query)
  lines = lines + add_no_ah_data_uuid_lines(results)
  return lines
end

# Helper method to print out HTML header indicating what type of output we're sending
def print_html_header
  puts "Content-type: #{@content_types[@output_type]}"
  puts "\n"
end

# Helper method to build out the @card_names hash
def build_card_names_hash(names=nil)
  return if names.nil?
  names.each do |name|
    if @card_names[name].nil?
      @card_names[name] = Hash.new
      @card_names[name]['uuid'] = ""
      @card_names[name]['GOLD'] = Array.new
      @card_names[name]['PLATINUM'] = Array.new
    end
  end
end

# Take raw lines in an array and turn them into a data structure we can use
def parse_lines(lines=nil, html=false)
  return if lines.nil?
  # Do this here because I wasn't smart enough to do this before...
  # Print out HTTP headers
  print_html_header
  # Get current time for comparison
  now = Time.now
  # Iterate through the lines and grab interesting info out
  lines.each do |line|
    parsed_line = line.gsub(/\r\n?/, "\n")
    # Run regexp against line and grab out interesting bits
    if parsed_line.match(/^(.*),(GOLD|PLATINUM),(\d+),?(.*?),?([a-f0-9-]+)?$/)
      name = $1
      currency = $2
      price = $3
      date = $4
      uuid = $5
# binding.pry
      (year, mon, day) = date.split(/[-\s:]/)
      old = Time.new(year, mon, day)
      age = ((now - old)/3600).to_i
      if age > @cutoff_time_in_hours
#        puts "Skipping because age of #{age} hours > #{@cutoff_time_in_hours} for #{name} - #{date}"
        next
      else
#        puts "#{name} - #{price} #{currency} - #{age}"
      end
      # Do replacements afterward so we don't mess up match variables
      name.gsub!(/"/, '')   # Get rid of any double quotes
      # Add price onto hash for access later
      # Make sure we build out the data structure as we need it
      if @card_names[name].nil?
        @card_names[name] = Hash.new
      end
      @card_names[name]['uuid'] = uuid
      if @card_names[name][currency].nil?
        # Explicitly make both currencies here so we won't be missing any if no auctions of that particular
        # type showed up in our window
        @card_names[name]['GOLD'] = Array.new
        @card_names[name]['PLATINUM'] = Array.new
      end
      # Make tuple here so we can use it later to sort on for calculating the moving average
      info = [ price.to_i, date]
      @card_names[name][currency] << info
      #@card_names[name][currency] << price.to_i
    end
  end
end

# Standard method for getting the integer average of an array
def array_int_avg(array=nil)
  # If we didn't get an actual array, return 0
  return 0 if array.nil?
  # If the array has 0 elements in it, return 0
  return 0 if array.size < 1
  # Use some array inject magic to sum all elements, then divide by the array size
  # Use float to keep fidelity until the next step
  average = array.inject{ |sum, el| sum + el }.to_f / array.size
  # Return the integer value of the average
  return average.to_i
end

# Get the average price of an array ignoring outliers
def get_average_price(prices=nil?)
  avg_price, size = get_full_price_details(prices)
  return avg_price, size
end

def get_median_price(prices=nil?)
  return 0 if prices.nil?
  return 0 if prices.length < 1
  sorted = prices.sort
  len = sorted.length
  median = (sorted[(len - 1) / 2] + sorted[len / 2]) / 2.0
  return median.to_i
end

# Method to get all details and distribution info about a set.
def get_full_price_details(prices=nil)
  # If we didn't get a proper array, set average to 0 and sample size to 0
  return 0, 0, 0, 0, 0, 0, 0, 0, 0 if prices.nil?
  # Extract out only the prices for use below
  local_prices = Array.new
  prices.each do |p|
    local_prices << p[0]
  end
  # if we have a small number of sales, just average and return the result
  if prices.size < 9
    median_price = get_median_price(local_prices)
    return median_price, local_prices.size, median_price, 0, 0, 0, 0, 0, 0
  end
  true_average = array_int_avg(local_prices)    # Get an initial average for the entire, pre-filtered array
  local_prices.sort!                            # Sort array numerically
  min = local_prices[0]                         # Store min and max for returning later
  max = local_prices[-1]
  median = (local_prices.size / 2).to_i         # Find median
  lq = (median / 2).to_i                  # Find lower quartile array index
  uq = ((median + local_prices.size) / 2).to_i  # Find upper quartile array index
  iqr = local_prices[uq] - local_prices[lq]           # IQR = upper - lower
  # Set upper and lower cutoff values
  lower_cutoff = local_prices[median] - (iqr * 1.5).to_i
  upper_cutoff = local_prices[median] + (iqr * 1.5).to_i
  # exclude outlier values below lower - (IQR * 1.5)
  excluded = Array.new
  p2 = Array.new                          # Create new Array
  prices.each {|value|                    # Iterate through values in prices
    next if value.nil?                    # Skip if this value somehow got set to nil
    if value[0] >= lower_cutoff           # If the value is greater than or equal to the lower of the cutoff values
      p2 << value                         # add it to p2
    else                                  # Otherwise
      excluded << value                   # And add it to our excluded array
    end
  } 
  prices = p2                             # Then make prices into p2
  # exclude outlier values above upper + (IQR * 1.5)
  p2 = Array.new                          # Reset p2 into new array
  prices.each {|value|                    # Iterate through values in prices
    next if value.nil?                    # Skip if this value somehow got set to nil
    if value[0] <= upper_cutoff           # If the value is less than or equal to the higher of the cutoff values
      p2 << value                         # add it to p2
    else                                  # Otherwise
      excluded << value                   # And add it to our excluded array
    end
  } 
  prices = p2                             # Then make prices into p2
#  avg_price = array_int_avg(prices)       # Average remaining values and return that (along with the sample size)
  # Now that we've exclude outliers, sort by date, then extract the prices and hand that off 
  # to get the exponential moving average price
  prices.sort! do |b, a|
    a_ary = a[1].split(/-/)
    a_ary[2].sub!(/,.*/, "")
    b_ary = b[1].split(/-/)
    b_ary[2].sub!(/,.*/, "")
    v = a_ary[1] <=> b_ary[1]
    if v == 0 then 
      v = a_ary[2] <=> b_ary[2]
      if v == 0 then 
        v = a_ary[3] <=> b_ary[3]
      end
    end
    v
  end
  bare_prices = Array.new
  prices.each do |p|
    next if p.nil?
    bare_prices << p[0]
  end
  avg_price = bare_prices.exponential_moving_average.to_i
  # Massage excluded array into a string, then remove the double quotes from it as that messes up CSV output
  excluded_string = excluded.to_s
  excluded_string.gsub!(/"/, '')               # Get rid of double quotes (which mess up CSV output)
  # Return all the appropriate values
  return avg_price, prices.size, true_average, min, lq, median, uq, max, excluded_string
end

def test(name='foo', filter=nil)
  puts name
  puts "Passed filter with '#{name}'"
end

# General print statement
def print_card_output(array=nil)
  return if array.nil?
  # Do some bits here to calculate price of a Draft Pack
  draft_format = { '003' => 3 }
  # We'll calculate 100 plat worth of gold presently and the 100 plat as well
  draft_pack_value = { 'GOLD' => 0, 'PLATINUM' => 0 }
  eval @card_field_descriptors[@output_type][@output_detail]
  array.sort.map do |name, currencies|
    next unless name.match(/#{@name_filter}/)
#    puts "Checking #{name} against /#{@exclude_filter}/"
    unless @exclude_filter.nil?
      next if name.match(/#{@exclude_filter}/)
    end
    str = ''
# binding.pry
    uuid = array[name]['uuid']
    eval @card_init_string[@output_type][@output_detail]
    currencies.sort.reverse.map do |currency, prices|
      next if currency == 'uuid'
#      puts "Working on #{name} and got the following prices for #{currency}: #{prices}"
      if prices.nil? then
        avg = sample_size = true_avg = min = lq = med = uq = max = excl = 0
      else
        avg, sample_size, true_avg, min, lq, med, uq, max, excl = get_full_price_details(prices)
      end
      eval @card_details_string[@output_type][@output_detail]
      draft_format.each_pair do |k, v|
        if name =~ /#{k} Booster Pack/ then
          draft_pack_value[currency] += (avg * v)
        end
      end
    end
    eval @card_closing_string[@output_type][@output_detail]
    puts str
  end
# binding.pry
  # Skip unless we've done anything with the draft booster pack prices
  unless draft_pack_value['PLATINUM'] == 0 then
    uuid = "draftpak-0000-0000-0000-000000000000"
    # Use the values we got for draft packs and calculate a gold to plat ratio 
    ratio = draft_pack_value['GOLD'] / draft_pack_value['PLATINUM']
    # Take that ratio, multiply it times 100 and add it to the GOLD draft_pack_value then add 100 to plat value
    draft_pack_value['GOLD'] += ratio * 100
    draft_pack_value['PLATINUM'] += 100
    # Init some vars and print out our computed draft pack value
    str = ''
    name = "'Computed Draft Booster Pack' [Common]"
    eval @card_init_string[@output_type][@output_detail]
    # Now, take those values and print out some stuff
    ['PLATINUM', 'GOLD'].each do |currency|
      avg = true_avg = min = lq = med = uq = max = draft_pack_value[currency] / 3
      sample_size = 1; excl = 0
      eval @card_details_string[@output_type][@output_detail]
    end
    eval @card_closing_string[@output_type][@output_detail]
    puts str
  end
  eval @card_closing_bits[@output_type][@output_detail]
end

# Print out requested cards
def print_filtered_output(array=nil, filter='.*')
  return if array.nil?
  @name_filter = filter
  @output_type = 'PSV'
  @output_detail = 'brief'
  print_card_output(array)
end

# Print out full details of requested cards
def print_filtered_detailed_output(array=nil, filter='.*', exclude=nil)
  return if array.nil?
  @name_filter = filter
  @exclude_filter = exclude
  @output_type = 'HTML'
  @output_detail = 'detailed'
  print_card_output(array)
end

# Print out cards in CSV format
def print_csv_output(array=nil, filter='.*', exclude=nil)
  return if array.nil?
  @name_filter = filter
  @exclude_filter = exclude
  @output_type = 'CSV'
  @output_detail = 'detailed'
  print_card_output(array)
end

# Print out price data csv format
def print_pdcsv_output(array=nil, filter='.*', exclude=nil)
  return if array.nil?
  @name_filter = filter
  @exclude_filter = exclude
  @output_type = 'PDCSV'
  @output_detail = 'brief'
  print_card_output(array)
end

