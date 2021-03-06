#!/usr/bin/env ruby
#
# Get the orange posts and stuff them in a database

require 'open-uri'
require 'nokogiri'
require 'pry'
require 'uri'
require 'mysql'
require 'date'  # For modifying 'Yesterday' and 'Today' into dates from post information
require 'fileutils'

@url_prefix = 'https://forums.hextcg.com/'
@url_scheme = "https"
@url_host = "forums.hextcg.com"
@curl_cmd = "curl -s -L "

@DEBUG=false

def pdebug(str=nil)
  return if str.nil?
  return unless @DEBUG == true
  puts "DEBUG: #{str}"
end

# Take the URLs in a page and make them into absolute URLs (instead of relative ones)
def make_urls_absolute(page)
  # find things using 'src' and 'href' parameters
  tags = {
    'img'    => 'src',
    'script' => 'src',
    'a'      => 'href'
  }
  begin
    page.search(tags.keys.join(',')).each do |node|
      url_param = tags[node.name]
      src = node[url_param]
      # Need to skip an href="javascript://" anchor tags because they break stuff
      next if src =~ /javascript/
      unless (src.nil? or src.empty?)
        uri = URI.parse(src)
        unless uri.host
        pdebug uri
          uri.scheme = @url_scheme
          uri.host = @url_host
          if uri.path !~ /^\// 
            uri.path = "/#{uri.path}"
          end
          node[url_param] = uri.to_s
        end
      end
    end
  rescue Exception => e
    pdebug "*** Error in trying to massage post URLs: #{e.message}"
  end
  return page
end

# Get the contents of a specific post
def retrieve_post(url="")
  pdebug "Getting post from #{url}'"
  page_text = %x( #{@curl_cmd} '#{url}' )
  initial_page = Nokogiri::HTML(page_text)
#  initial_page = Nokogiri::HTML(open(url))
  page = make_urls_absolute(initial_page)

  post_id = url[/postID=(\d+)/, 1]
  title = page.css("header.boxHeadline.marginTop.wbbThread.labeledHeadline > h1").text.gsub!(/[\r\n\t]/, '')
  contents = page.css("li#post#{post_id}.marginTop article div section.messageContent div div.messageBody div div.messageText").to_s.gsub!(/[\t]/, '')
  date = page.css("li#post#{post_id}.marginTop article div section.messageContent div header div p time")[0].values[0]
  # Massage out the T and GMT offset.
  date.gsub!(/T/, ' ').gsub!(/\+\d+:00$/, '')

  return [ title, contents, date ]
end

# Get the list of posts by a specific user
def get_user_post_list(userid="1")
  # Construct search URL
  #search_url = "http://forums.cryptozoic.com/search.php?do=finduser&userid=#{userid}&contenttype=vBForum_Post&showposts=1"
  search_url = "#{@url_prefix}index.php?search/&types%5B%5D=com.woltlab.wbb.post&userID=#{userid}"
  pdebug "Trying to get '#{search_url}'"
  # Retrieve page
  begin
    page_text = %x( #{@curl_cmd} '#{search_url}' )
    page = Nokogiri::HTML(page_text)
  #  page = Nokogiri::HTML(open(search_url))
  rescue OpenURI::HTTPError => e
    if e.message == '404 Not Found' then
      # Likely means they've got no posts
      return
    else
      raise e
    end
  end

  return_array = Array.new
  # Parse page and extract out the URLs for the individual posts
  # I should understand how this works, but I mostly figured this out empirically
  body = page.css("ul.containerList.messageSearchResultList")
  
  # Doing this with xpath
  #body.xpath('//h3[@class="posttitle"]/a').each do |li| 
  # Doing this with CSS
  body.css('div.containerHeadline > h3 > a').each do |li| 
    return_array << "#{li.values[0]}"
  end
  pdebug "Got this array of posts: #{return_array}"
  #binding.pry
  return return_array
end

def get_db_con
  pw = File.open("/home/docxstudios/hex_tcg.pw").read.chomp
  con = Mysql.new 'mysql.doc-x.net', 'hex_tcg', pw, 'hex_tcg'
end

def store_post(con = nil, thread_id = nil, post_id = nil, title = nil, orange_id = nil, post_date = nil, url = nil, contents = nil)
  # Make sure we have everything we need for a proper post entry
  return if thread_id.nil? or post_id.nil? or title.nil? or orange_id.nil? or url.nil? or contents.nil?
  # Escape everything so it's digestable by mysql
  contents = Mysql.escape_string contents
  thread_id = Mysql.escape_string thread_id
  post_id = Mysql.escape_string post_id
  title = Mysql.escape_string title
  post_date = Mysql.escape_string post_date
  url = Mysql.escape_string url
  contents = Mysql.escape_string contents
  #query = "insert into orange_posts set thread_id='#{thread_id}', post_id='#{post_id}', title='#{title}', orange_id='#{orange_id}', post_date='#{post_date}', url='#{url}', contents='#{contents}' on duplicate key update thread_id='#{thread_id}', post_date='#{post_date}', title='#{title}', orange_id='#{orange_id}', url='#{url}', contents='#{contents}'"
  query = "REPLACE INTO orange_posts set thread_id='#{thread_id}', post_id='#{post_id}', title='#{title}', orange_id='#{orange_id}', post_date='#{post_date}', url='#{url}', contents='#{contents}'"
  con.query(query)
  pdebug "Stored data for post #{post_id} in thread #{thread_id}"
end

# Given a userid and a sql connection, get all of the user's posts and stuff them into the table
def get_user_posts(orange_id=nil, sql_con=nil)
  return if sql_con.nil?
  return if orange_id.nil?
  posts = get_user_post_list(orange_id)
  return if posts.nil?
  posts.each do |url|
    pdebug "Retrieving #{url}"
    thread_id = url[/thread\/(\d+[^\/]+)/, 1]
    post_id = url[/postID=(\d+)/, 1]
    pdebug "Thread id: #{thread_id} and Post id: #{post_id}"
    title, contents, post_date = retrieve_post(url)
    pdebug "Title: #{title} and date: #{post_date}"
    pdebug "Contents: #{contents}"
    store_post(sql_con, thread_id, post_id, title, orange_id, post_date, url, contents)
#binding.pry
    sleep 3
  end
end

# Return an array of all of the Orange userids
def get_orange_ids(sql_con=nil)
  return if sql_con.nil?
  query = "select userid from orange where inactive is NULL;"
  # Some kung fu here. Take the Mysql result, turn it into an Enumerable, then collect that and
  # grab the first bit of each row (which is the userid we asked for before). All of this becomes
  # an array that gets passed out of the method
  sql_con.query(query).to_enum.collect { |row| "#{row[0].to_s}"}
end

#### MAIN STARTING
FileUtils.touch('/home/docxstudios/web/hex/get_orange_start')
sql_con = get_db_con
userids = get_orange_ids(sql_con)
#userids = [ 15 ]      # Testing grabbing Chark's posts
#userids = [ 10 ]      # Testing grabbing Chark's posts
userids.each do |uid|
  pdebug uid
  get_user_posts(uid, sql_con)
  sleep 1;
end
FileUtils.touch('/home/docxstudios/web/hex/get_orange_end')
