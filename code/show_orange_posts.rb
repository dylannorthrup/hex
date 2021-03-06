#!/usr/bin/env ruby
#
# Get Orange posts from database and show them

#require 'pry'
require 'mysql'
require 'cgi'

# Some useful variables
@user_info_url = 'https://forums.hextcg.com/index.php?user/'

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
  puts "<tr><td class='orange_poster' align=left><a href='#{@user_info_url}#{orange_id}-#{name.gsub(/_/, '-')}'>#{name}</a></td></tr>"
  puts "<tr><th class='thread_title'>posted in thread <a class='thread_title' href='#{url}'>#{title}</a> on #{post_date} </th></tr>"
  puts "<tr><td class='post_contents' align=left><blockquote>#{contents}</td></tr></table></center>"
end

# Get the posts we have information for. By default, limit this to 100
def get_posts(sql_con=nil, limit=20)
  return if sql_con.nil?
  # Even though we do explicit sorting later by date, we order by post_date here for when we get a subset
  # of posts (so we're getting the right subset)
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

def show_adsense()
  puts "<p><hr></p>"
  puts "<style>"
  puts "begging{ width: 70%; }"
  puts "</style>"
  puts "<center><table border=0 width=80%>"
  puts "<tr><td class='post_contents'>
My In Game Name is 'Dylan'.  If you like this page, the service it provides and are so inclined, feel free to 
take a look at my <a href='/hex/have-want.txt'>want list</a> and throw me a card or two.  If you don't have 
any of those, throw some Gold my way (or Plat, if you have any extra).  If you want posts from the old Cryptozoic 
forums, they're archived <a href='/hex/old_orange_posts.html'>here</a> for posterity.  If you want posts from the GameForge 
forums, they're archiged <a href='/hex/gf_orange_posts.html'>here</a> for posterity. And if you want the latest and greatest
from the current forums, enjoy . . . </td></tr></table></center>"
  puts "<p><hr></p>"
end

# A named proc to use for sorting post dates
post_date_sort = ->(a,b) {
    a_date = a[4]; b_date = b[4];
    # Replace non digits with dashes for easier splitting
    astr = a_date.gsub(/[:, ]+/, '-')
    bstr = b_date.gsub(/[:, ]+/, '-')
    # Split on '-' to get all the bits
    (ayr, amo, ada, ahr, amn, aap) = astr.split(/-/)
    (byr, bmo, bda, bhr, bmn, bap) = bstr.split(/-/)
    # Make hour strings into integers
    ahi = ahr.gsub(/\D+/,'').to_i; bhi = bhr.gsub(/\D+/,'').to_i
    # A little modification for 12AM and 12PM to make them fit in properly (since
    # 12:01 AM should go before 1:01 AM, but without this modification it doesn't)
    if ahi == 12; ahi = 0; end
    if bhi == 12; bhi = 0; end
    # Then bump their value 12 hours if the time's in the PM
    ahi += 12 if aap.match('PM')
    bhi += 12 if bap.match('PM')
    comparables = [[byr, ayr], [bmo, amo], [bda, ada], [bhi, ahi], [bmn, amn]]
    # Now, go through the pairs and compare them
    comparables.each do |thingy|
      # See if there's a difference
      diff = thingy[0].to_i <=> thingy[1].to_i
      # If they aren't equal, return that comparison
      if (diff != 0)
        return diff
      end
    end
    # And since this is the last thing, we can just compare like normal
#    [bmn.to_i] <=> [amn.to_i]
    # If we get this far, everything's equal, so return 0
    return 0    
}

#### MAIN STARTING

cgi = CGI.new
params = cgi.params

puts "Content-type: text/html;  charset=utf-8"
puts ""
puts "<html><head><title>Orange Tracker</title>"
puts '<link rel="stylesheet" type="text/css" href="/hex/orange_posts.css">'
puts '<link rel="stylesheet" type="text/css" href="/hex/gf-main.css">'
puts "</head><body>"
puts "<h1 class='orange_header'>Orange Tracker (now with 100% less GameForge)</h1>"
show_adsense
sql_con = get_db_con
if params['all'][0] =~ /true/
  puts "<p style='font-size:20px'><a href='/hex#{cgi.path_info}'>Get recent Orange posts</a></p>"
  posts = get_all_posts(sql_con)
  posts.sort( & post_date_sort ).each do |thing|
    print_post(thing)
  end
  puts "<a href='/hex#{cgi.path_info}'>Get recent Orange posts</a>"
else
  puts "<p style='font-size:20px'><a href='/hex#{cgi.path_info}?all=true'>Get all Orange posts</a></p>"
  posts = get_posts(sql_con)
  posts.sort( & post_date_sort ).each do |thing|
    print_post(thing)
  end
  puts "<a href='/hex#{cgi.path_info}?all=true'>Get all Orange posts</a>"
end

puts "</body></html>"
