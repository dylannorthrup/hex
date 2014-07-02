#!/usr/bin/env ruby
#
# Get Orange posts from database and show them

require 'pry'
require 'mysql'


def get_db_con
  pw = File.open("/home/docxstudios/hex.sql.pws").read.chomp
  con = Mysql.new 'mysql.doc-x.net', 'hex_reader', pw, 'hex_tcg'
end

# Hand this an array and it should print out a table with the post information
def print_post(row=nil)
  return if row.nil?
  title = row[0]
  name = row[1]
  url = row[2]
  contents = row[3]
  post_date = row[4]
  puts "#{title} - (#{name}) - #{post_date}"
  puts url
end

# Get the posts we have information for. By default, limit this to 20
def get_posts(sql_con=nil, limit=20)
  return if sql_con.nil?
  query = "select p.title, o.name, p.url, p.contents, p.post_date from orange_posts as p, orange as o where o.userid = p.orange_id order by p.post_date desc limit #{limit}"
  sql_con.query(query).to_enum
end

# Get every post we have
def get_all_posts(sql_con=nil)
  return if sql_con.nil?
  query = "select count(*) from orange_posts"
  num = sql_con.query(query).to_enum.collect { |row| "#{row[0].to_s}"}[0]
  get_posts(sql_con, num)
end

#### MAIN STARTING
sql_con = get_db_con
get_posts(sql_con).each do |thing|
  print_post(thing)
end
