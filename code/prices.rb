#!/usr/bin/env ruby
#
# get prices for rare and legendary cards for both gold and platinum from Hex price data

$: << "/home/docxstudios/web/hex/code"
require 'mysql'
require 'Hex'

#@fname = "AH_Sold_Cards_unix.csv"
@fname = "AH_Sold_Cards.csv"
@price_data = Hash.new
@card_names = Hash.new

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

def read_db(sqlcon=nil, filter='')
  return if sqlcon.nil?
  lines = Array.new
  # Select from database to get all bits
  query = "SELECT ah.name, ah.currency, ah.price, c.rarity FROM ah_data ah, cards c where c.name = ah.name #{filter}"
  results = sqlcon.query(query)
  results.each do |row|
    line = "#{row[0]},#{row[1]},#{row[2]},#{row[3]}"
    lines << line
  end
  return lines
end

def parse_lines(lines=nil, html=false)
  return if lines.nil?
  # Do this here because I wasn't smart enough to do this before...
  # Print out HTTP headers
  if html
    puts "Content-type: text/html"
    puts ""
  else
    puts "Content-type: text/plain"
    puts ""
  end
  #
  lines.each do |line|
    parsed_line = line.gsub(/\r\n?/, "\n")
    # Run regexp against line and grab out interesting bits
    if parsed_line.match(/^(.*),(GOLD|PLATINUM),(\d+),(.*)$/)
      name = "'#{$1}' [#{$4}]"
      currency = $2
      price = $3
      # Do replacements afterward so we don't mess up match variables
      name.gsub!(/"/, '')   # Get rid of any double quotes
      # Add price onto hash for access later
      # TODO: We can put a date check in here to expire off data later.
      # Make sure we build out the data structure as we need it
      if @card_names[name].nil?
        @card_names[name] = Hash.new
      end
      if @card_names[name][currency].nil?
        @card_names[name][currency] = Array.new
      end
      @card_names[name][currency] << price.to_i
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
  return 0, 0 if prices.nil?
  # if we have a small number of sales, just average and return the result
  if prices.size < 9
    avg_price = array_int_avg(prices)
    return avg_price, prices.size, avg_price
  end
  true_average = array_int_avg(prices)    # Get an initial average for the entire, pre-filtered array
  prices.sort!                            # Sort array numerically
  min = prices[0]                         # Store min and max for returning later
  max = prices[-1]
  median = (prices.size / 2).to_i         # Find median
  lq = (median / 2).to_i                  # Find lower quartile array index
  uq = ((median + prices.size) / 2).to_i  # Find upper quartile array index
  iqr = prices[uq] - prices[lq]           # IQR = upper - lower
  # Set upper and lower cutoff values
  lower_cutoff = prices[median] - (iqr * 1.5).to_i
  upper_cutoff = prices[median] + (iqr * 1.5).to_i
  # exclude outlier values below lower - (IQR * 1.5)
  excluded = Array.new
  p2 = Array.new                          # Create new Array
  prices.each {|value|                    # Iterate through values in prices
    next if value.nil?                    # Skip if this value somehow got set to nil
    if value >= lower_cutoff              # If the value is greater than or equal to the lower of the cutoff values
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
    if value <= upper_cutoff              # If the value is less than or equal to the higher of the cutoff values
      p2 << value                         # add it to p2
    else                                  # Otherwise
      excluded << value                   # Add it to our excluded array
    end
  } 
  prices = p2                             # Then make prices into p2
  avg_price = array_int_avg(prices)       # Average remaining values and return that (along with the sample size)
  # Return all the appropriate values
  return avg_price, prices.size, true_average, min, lq, median, uq, max, excluded
end

# Print out requested cards
def print_filtered_output(array=nil, filter='.*')
  return if array.nil?
  array.each_pair do |name, currencies|
    next unless name.match(/#{filter}/)
    str = "* #{name}"
    currencies.each_pair do |currency, prices|
      (avg, sample_size) = get_average_price(prices)
      str << " ... #{avg} #{currency} [#{sample_size} auctions]"
    end
    puts str
  end
end

# Print out full details of requested cards
def print_filtered_detailed_output(array=nil, filter='.*')
  return if array.nil?
  array.each_pair do |name, currencies|
    next unless name.match(/#{filter}/)
    str = "#{name.gsub(/^'/, '').gsub(/' \[.*\]$/, '')}"
    avg, sample_size, true_avg, min, lq, med, uq, max, excl = get_full_price_details(currencies['PLATINUM'])
    str << "|PLATINUM|#{avg}|#{sample_size} auctions|#{true_avg}|#{min}|#{lq}|#{med}|#{uq}|#{max}|#{excl}"
    avg, sample_size, true_avg, min, lq, med, uq, max, excl = get_full_price_details(currencies['GOLD'])
    str << "|GOLD|#{avg}|#{sample_size} auctions|#{true_avg}|#{min}|#{lq}|#{med}|#{uq}|#{max}|#{excl}"
    puts str
  end
end

# Print out full details of requested cards
def print_filtered_detailed_output(array=nil, filter='.*')
  return if array.nil?
  puts "<div class='CSSTableGenerator'><table><tr><th>Card Name</th><th>Currency</th><th>Avg w/o outliers</th><th>Number of auctions</th><th>Average with outliers</th><th>Min price</th><th>1st quartile price</th><th>Median price</th><th>3rd quartile price</th><th>Max price</th><th>Excluded values</th><th>Currency</th><th>Avg w/o outliers</th><th>Number of auctions</th><th>Average with outliers</th><th>Min price</th><th>1st quartile price</th><th>Median price</th><th>3rd quartile price</th><th>Max price</th><th>Excluded values</th></tr>"
  array.each_pair do |name, currencies|
    next unless name.match(/#{filter}/)
    str = "<tr><td>#{name.gsub(/^'/, '').gsub(/' \[.*\]$/, '')}"
    avg, sample_size, true_avg, min, lq, med, uq, max, excl = get_full_price_details(currencies['PLATINUM'])
    str << "</td><td>PLATINUM</td><td>#{avg}</td><td>#{sample_size} auctions</td><td>#{true_avg}</td><td>#{min}</td><td>#{lq}</td><td>#{med}</td><td>#{uq}</td><td>#{max}</td><td>#{excl}"
    avg, sample_size, true_avg, min, lq, med, uq, max, excl = get_full_price_details(currencies['GOLD'])
    str << "</td><td>GOLD</td><td>#{avg}</td><td>#{sample_size} auctions</td><td>#{true_avg}</td><td>#{min}</td><td>#{lq}</td><td>#{med}</td><td>#{uq}</td><td>#{max}</td><td>#{excl}</td></tr>"
    puts str
  end
  puts "</table></div>"
end

# Print out cards in CSV format
def print_csv_output(array=nil, filter='.*')
  return if array.nil?
  array.each_pair do |name, currencies|
    next unless name.match(/#{filter}/)
    puts "#{name.gsub(/^'/, '').gsub(/' \[.*\]$/, '')}|#{(get_average_price(currencies['PLATINUM']))[0]}|#{(get_average_price(currencies['GOLD']))[0]}"
  end
end

# Print out cards in CommaSV format
def print_csv_output(array=nil, filter='.*')
  return if array.nil?
  array.each_pair do |name, currencies|
    next unless name.match(/#{filter}/)
    puts "#{(get_average_price(currencies['PLATINUM']))[0]},#{(get_average_price(currencies['GOLD']))[0]},#{name.gsub(/^'/, '"').gsub(/' \[.*\]$/, '"')}"
  end
end


