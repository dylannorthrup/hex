#!/usr/bin/ruby

require 'cgi'
cgi = CGI.new

puts "Content-type: text/plain\n"
puts "Content accepted"
File.open('/Users/dnorthrup/temp/hex/dr/api.data', 'w') { |f| f.write("#{cgi.keys}\n") }

