#!/usr/bin/env ruby
#
# Take price data and stuff it into a database

require "mysql"

#@fname = "AH_Sold_Cards.csv"
@fname = "AH_Sold_Cards_20140811.csv"
@card_names = Hash.new

# Read in AH data from CSV file
def read_file(fname=nil)
  return if fname.nil?
  # Array we use to store entries
  lines = Array.new
  ah_data = Array.new
  # Deal with DOS line endings by reading in file, then manually splitting on DOS line ending
  File.open(fname).each_line do |line|
    lines = line.split(/\r\n?/).map(&:chomp)
  end
  return lines
end

DB_CREATE_STRING = "CREATE TABLE IF NOT EXISTS ah_data(name VARCHAR(50), currency VARCHAR(20), price INT, sale_date VARCHAR(40), count INT);"

def print_out_sql(lines=nil)
  return if lines.nil?
  puts DB_CREATE_STRING
  lines.each do |line|
    parsed_line = line.gsub(/\r\n?/, "\n")
    # Run regexp against line and grab out interesting bits
    #if parsed_line.match(/^(.*),(GOLD|PLATINUM),(\d+),(.*),(\d+)$/)
    if parsed_line.match(/^"?\s*(.*?)\s*"?,\s*(GOLD|PLATINUM)\s*,\s*(\d+)\s*,\s*(.*?)\s*$/)
      name = $1
      currency = $2
      price = $3
      date = $4
      #count = $5
      count = "1"
      # Do replacements afterward so we don't mess up match variables
      name.gsub!(/"/, '')   # Get rid of any double quotes
      puts "INSERT INTO ah_data values ('#{Mysql.escape_string name}','#{Mysql.escape_string currency}',#{Mysql.escape_string price},'#{Mysql.escape_string date}',#{Mysql.escape_string count});"
    end
  end
end

####### MAIN SECTION
lines = read_file(@fname)                 # Get data from file
print_out_sql(lines)                          # Take that data and make database statements out of it
