#!/usr/bin/env ruby
#
# get distribution of prices for card for both gold and platinum from Hex price data

$: << "/home/docxstudios/web/hex/code"
require 'prices_test'
require 'cgi'
require 'pry'

uuid = ""

cgi = CGI.new
params = cgi.params

# Make sure we have some params
if params.empty?
  cgi.out("status" => "BAD_REQUEST") {
    "No search parameters provided\n"
  }
end

# Make sure we have a UUID
if params['uuid'].empty?
  cgi.out("status" => "BAD_REQUEST") {
    "No uuid parameter provided\n"
  }
else
  uuid = params['uuid'][0]
end

# Validate UUID
unless uuid =~ /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/
  cgi.out("status" => "BAD_REQUEST") {
    "Invalid uuid parameter provided '#{uuid}'\n"
  }
end

####### MAIN SECTION
@output_type = 'PDCSV'
@output_detail = 'brief'
foo = Hex::Collection.new
con = foo.get_db_con
lines = read_db(con, "and c.uuid LIKE '#{uuid}'")                      # Get data from database
parse_lines(lines)                        # Compile that data into a useable form
print_card_output(@card_names)
