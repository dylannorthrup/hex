#!/usr/bin/env ruby
#
# Take price data and stuff it into a database

require "mysql"

@card_names = Hash.new

@set_names = {
  'Set 001' => 'Shards of Fate',
  'Set 002' => 'Shatterd Destiny',
  'Set 003' => 'Armies of Myth',
  'Set 004' => 'Primal Dawn',
  'Set 005' => 'Herofall',
}

def get_db_con
  pw = File.open("/home/docxstudios/hex_tcg.pw").read.chomp
  con = Mysql.new 'mysql.doc-x.net', 'hex_tcg', pw, 'hex_tcg'
end

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

DB_CREATE_STRING = "CREATE TABLE IF NOT EXISTS ah_data(name VARCHAR(50), currency VARCHAR(20), price INT, sale_date VARCHAR(40), rarity INT);"

def insert_data(sql_con=nil, lines=nil)
  return if sql_con.nil?
  return if lines.nil?
  query = DB_CREATE_STRING
  sql_con.query(query)
  lines.each do |line|
    parsed_line = line.gsub(/\r\n?/, "\n")
    # Run regexp against line and grab out interesting bits
    #if parsed_line.match(/^(.*),(GOLD|PLATINUM),(\d+),(.*),(\d+)$/)
    if parsed_line.match(/^\s*(.*?)\s*,\s*(\d+)\s*,\s*(GOLD|PLATINUM)\s*,\s*(\d+)\s*,\s*(.*?)\s*,\s*([a-f0-9-]*?)\s*$/)
      name = $1
      rarity = $2
      currency = $3
      price = $4
      date = $5
      uuid = $6
      # Do replacements afterward so we don't mess up match variables
      name.gsub!(/"/, '')   # Get rid of any double quotes
      if name.match(/^(Set ...) Booster Pack/)
        new_name = "#{@set_names[$1]} Booster Pack"
        name = new_name
      end
      query = "INSERT INTO ah_data values ('#{Mysql.escape_string name}','#{Mysql.escape_string currency}',#{Mysql.escape_string price},'#{Mysql.escape_string date}',#{Mysql.escape_string rarity},'#{Mysql.escape_string uuid}');"
      sql_con.query(query)
    else
      puts "ERROR: Line did not match regexp: '#{parsed_line}'"
    end
  end
end

def print_out_sql(lines=nil)
  return if lines.nil?
  puts DB_CREATE_STRING
  lines.each do |line|
    parsed_line = line.gsub(/\r\n?/, "\n")
    # Run regexp against line and grab out interesting bits
    #if parsed_line.match(/^(.*),(GOLD|PLATINUM),(\d+),(.*),(\d+)$/)
    if parsed_line.match(/^\s*(.*?)\s*,\s*(\d+)\s*,\s*(GOLD|PLATINUM)\s*,\s*(\d+)\s*,\s*(.*?)\s*$/)
      name = $1
      rarity = $2
      currency = $3
      price = $4
      date = $5
      # Do replacements afterward so we don't mess up match variables
      name.gsub!(/"/, '')   # Get rid of any double quotes
      puts "INSERT INTO ah_data values ('#{Mysql.escape_string name}','#{Mysql.escape_string currency}',#{Mysql.escape_string price},'#{Mysql.escape_string date}',#{Mysql.escape_string rarity});"
    else
      puts "ERROR: Line did not match regexp: '#{parsed_line}'"
    end
  end
end

####### MAIN SECTION
Dir.chdir('/home/docxstudios/web/hex/code')
sql_con = get_db_con
gzip_cmd = 'gzip -f9'

Dir.foreach('csvs') do |fname|
  next unless fname =~ /csv$/
  puts "Processing Hex price data from #{fname}"
  lines = File.readlines("csvs/#{fname}")
  insert_data(sql_con, lines)                    # Take that data and shove it into the database
  #print_out_sql(lines)                          # Take that data and make database statements out of it
  file_gzip_cmd = "#{gzip_cmd} csvs/#{fname}"
  system( file_gzip_cmd )
end
