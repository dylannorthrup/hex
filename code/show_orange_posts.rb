#!/usr/bin/env ruby
#
# Get Orange posts from database and show them

require 'pry'
require 'mysql'
require 'cgi'

# Some useful variables
@user_info_url = 'http://forums.cryptozoic.com/member.php?u='

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
  orange_id = row[5]
  # Get rid of wierd characters in the post date
  post_date.gsub!(/,.*?(\d)/, ', \1')
  # Do some massaging of the contents to unescape things that were escaped in mysql
  contents.gsub!(/\t/, '  ')
  contents.gsub!(/\\r\\n/, "")
  contents.gsub!(/\\n/, "")
  contents.gsub!(/\"/, '"')
  contents.gsub!(/\\\'/, "'")
  contents.gsub!(/\\"/, '')
  puts "<p><hr><p><center><table border=1 width=80%>"
  puts "<tr><td class='orange_poster' align=left><a href='#{@user_info_url}#{orange_id}'>#{name}</a></td></tr>"
  puts "<tr><th class='thread_title'>posted in thread <a class='thread_title' href='#{url}'>#{title}</a> on #{post_date} </th></tr>"
  puts "<tr><td align=left><blockquote>#{contents}</td></tr></table></center>"
end

# Get the posts we have information for. By default, limit this to 20
def get_posts(sql_con=nil, limit=20)
  return if sql_con.nil?
  query = "select p.title, o.name, p.url, p.contents, p.post_date, p.orange_id from orange_posts as p, orange as o where o.userid = p.orange_id order by p.post_date desc limit #{limit}"
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

cgi = CGI.new
params = cgi.params

puts "Content-type: text/html"
puts ""
puts "<html><head><title>Orange Tracker</title>"
puts '<link rel="stylesheet" type="text/css" href="/hex/orange_posts.css">'
puts "</head><body>"
puts "<h1>Orange Tracker</h1>"
sql_con = get_db_con
if params['all'][0] =~ /true/
  puts "<a href='/hex#{cgi.path_info}'>Get recent Orange posts</a>"
  get_all_posts(sql_con).each do |thing|
    print_post(thing)
  end
  puts "<a href='/hex#{cgi.path_info}'>Get recent Orange posts</a>"
else
  puts "<a href='/hex#{cgi.path_info}?all=true'>Get all Orange posts</a>"
  get_posts(sql_con).each do |thing|
    print_post(thing)
  end
  puts "<a href='/hex#{cgi.path_info}?all=true'>Get all Orange posts</a>"
end

puts "</body></html>"
