#!/usr/bin/env ruby

puts "Content-type: text/plain\n"
puts "\n"
puts "Hello"
puts "QS: #{ENV['QUERY_STRING']}"
#ENV.each_pair do |k, v|
#puts "#{k}: #{v}"
#end
