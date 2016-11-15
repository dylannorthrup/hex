#!/usr/bin/env ruby
#
# get distribution of prices for card for both gold and platinum from Hex price data

$: << "/home/docxstudios/web/hex/code"
require 'prices_test'
require 'cgi'
require 'pry'

cgi = CGI.new
params = cgi.params
if params.empty?
  cgi.out("status" => "BAD_REQUEST") {
    "No search parameters provided"
  }
end
if params['uuid'].empty?
  cgi.out("status" => "BAD_REQUEST") {
    "No uuid parameter provided"
  }
end

####### MAIN SECTION
@output_type = 'PDCSV'
@output_detail = 'brief'
foo = Hex::Collection.new
con = foo.get_db_con
lines = read_db(con, "and c.uuid LIKE '674679f6-af3d-41d2-9e20-ae68d1816c71'")                      # Get data from database
parse_lines(lines)                        # Compile that data into a useable form
print_card_output(@card_names)
