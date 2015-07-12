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
  'HTML'  => 'text/html',     # HTML Tables
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
  'HTML'   => {
    'brief'     => 'puts "</table></div>"',
    'detailed'  => 'puts "</table></div>"',
  }
}
@card_field_descriptors = {
  'CSV'   => {
    'brief'     => 'puts "Name,Avg_price,Currency,# of auctions,Avg_price,Currency,# of auctions"',
    'detailed'  => 'puts "\"Name\",\"Rarity\",\"Currency\",Weighted Average Price,# of Auctions,Average Price,Min price,Lower Quartile,Median,Upper Quartile,Maximum Price,Excluded Prices,\"Currency\",Weighted Average Price,# of Auctions,Average Price,Min price,Lower Quartile,Median,Upper Quartile,Maximum Price,Excluded Prices"'
  },
  'PDCSV'   => {
    'brief'     => '',
    'detailed'  => 'puts "Average Price (Plat), Average Price (Gold),\"Name\"'
  },
  'PSV'   => {
    'brief'     => 'puts "Name ... Avg_price Currency [# of auctions] ... Avg_price Currency [# of auctions]"',
    'detailed'  => 'puts "Name|Rarity|Currency|Weighted Average Price|# of Auctions|Average Price|Min price|Lower Quartile|Median|Upper Quartile|Maximum Price|Excluded Prices|Currency|Weighted Average Price|# of Auctions|Average Price|Min price|Lower Quartile|Median|Upper Quartile|Maximum Price|Excluded Prices"'
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
  'HTML'  => {
    'brief'     => 'str << "<td>#{currency}</td><td>#{avg}</td><td>#{sample_size}</td><td>#{true_avg}</td><td>#{min}</td><td>#{lq}</td><td>#{med}</td><td>#{uq}</td><td>#{max}</td><td>#{excl}</td>"',
    'detailed'  => 'str << "<td>#{currency}</td><td>#{avg}</td><td>#{sample_size}</td><td>#{true_avg}</td><td>#{min}</td><td>#{lq}</td><td>#{med}</td><td>#{uq}</td><td>#{max}</td><td>#{excl}</td>"',
  }
}
@card_closing_string = {
  'CSV'   => {
    'brief'     => '',
    'detailed'  => '',
  },
  'PDCSV'   => {
    'brief'     => 'str << "\"#{name.gsub(/^\'/, \'\').gsub(/\' \[(.*)\]$/, "\"")}"',
    'detailed'  => 'str << "\"#{name.gsub(/^\'/, \'\').gsub(/\' \[(.*)\]$/, "\"")}"',
  },
  'PSV'   => {
    'brief'     => '',
    'detailed'  => '',
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
  query = "SELECT c.name, c.rarity FROM cards c where c.rarity not regexp 'Epic' #{filter}"
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
def read_db(sqlcon=nil, filter='')
  return if sqlcon.nil?
  lines = Array.new
  # Select from database to get all bits
  # We filter out 'Epic' rarity because it creates duplicates in the output. We take care of that by
  # looking at the sales data, though
  query = "SELECT ah.name, ah.currency, ah.price, c.rarity, ah.sale_date, ah.rarity FROM ah_data ah, cards c where replace(c.name, ',', '') = ah.name and c.rarity not regexp 'Epic' #{filter}"
  results = sqlcon.query(query)
  results.each do |row|
    name = row[0]
    rarity = row[3]
    if row[5].match(/5/) then
      name << " AA"
      rarity = 'Epic'
    end
    line = "'#{name}' [#{row[3]}],#{row[1]},#{row[2]},#{row[4]},#{row[5]}"
    #puts line
    lines << line
  end
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
    if parsed_line.match(/^(.*),(GOLD|PLATINUM),(\d+),?(.*)$/)
      name = $1
      currency = $2
      price = $3
      date = $4
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
    avg_price = array_int_avg(local_prices)
    return avg_price, local_prices.size, avg_price
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
    if value[0] >= lower_cutoff              # If the value is greater than or equal to the lower of the cutoff values
      p2 << value                         # add it to p2
    else                                  # Otherwise
      excluded << value                   # Add it to our excluded array
    end
  } 
  prices = p2                             # Then make prices into p2
  # exclude outlier values above upper + (IQR * 1.5)
  p2 = Array.new                          # Reset p2 into new array
  prices.each {|value|                    # Iterate through values in prices
    next if value.nil?                    # Skip if this value somehow got set to nil
    if value[0] <= upper_cutoff              # If the value is less than or equal to the higher of the cutoff values
      p2 << value                         # add it to p2
    else                                  # Otherwise
      excluded << value                   # Add it to our excluded array
    end
  } 
  prices = p2                             # Then make prices into p2
#  avg_price = array_int_avg(prices)       # Average remaining values and return that (along with the sample size)
  # Now that we've exclude outliers, sort by date, then extract the prices and hand that off 
  # to get teh exponential moving average price
  prices.sort do |a, b|
    a[1] <=> b[1]
  end
  bare_prices = Array.new
  prices.each do |p|
    bare_prices << p[0]
  end
  avg_price = bare_prices.exponential_moving_average.to_i
  # Return all the appropriate values
  return avg_price, prices.size, true_average, min, lq, median, uq, max, excluded
end

def test(name='foo', filter=nil)
  puts name
  puts "Passed filter with '#{name}'"
end

# General print statement
def print_card_output(array=nil)
  return if array.nil?
  # Do some bits here to calculate price of a Draft Pack
  draft_format = { '002' => 2, '001' => 1 }
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
    eval @card_init_string[@output_type][@output_detail]
    currencies.sort.reverse.map do |currency, prices|
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
  # Skip unless we've done anything with the draft booster pack prices
  unless draft_pack_value['PLATINUM'] == 0 then
    # Use the values we got for draft packs and calculate a gold to plat ratio 
    ratio = draft_pack_value['GOLD'] / draft_pack_value['PLATINUM']
    # Take that ratio, multiply it times 100 and add it to the GOLD draft_pack_value then add 100 to plat value
    draft_pack_value['GOLD'] += ratio * 100
    draft_pack_value['PLATINUM'] += 100
    # Init some vars and print out our computed draft pack value
    str = ''
    name = "Computed Draft Booster Pack"
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

## Print out full details of requested cards
#def print_filtered_detailed_output(array=nil, filter='.*')
#  return if array.nil?
#  array.sort.map do |name, currencies|
#    next unless name.match(/#{filter}/)
#    str = "#{name.gsub(/^'/, '').gsub(/' \[.*\]$/, '')}"
#    currencies.sort.map do |currency, prices|
#      avg, sample_size, true_avg, min, lq, med, uq, max, excl = get_full_price_details(prices)
#      str << "|#{currency}|#{avg}|#{sample_size} auctions|#{true_avg}|#{min}|#{lq}|#{med}|#{uq}|#{max}|#{excl}"
#    end
#    puts str
#  end
#end

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

