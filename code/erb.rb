#!/usr/bin/env ruby
#
# Test out ERB templating

# Print out HTTP headers
puts "Content-type: text/plain"
puts ""

##require "pry"
#$: << "/home/docxstudios/web/hex/code"
##binding.pry
require 'erb'

class Testing
  attr_accessor :blah, :temp_str

  def initialize
    @temp_str = "This is a template and here's the value: <%= @blah %>"
    @blah = 1
  end

  def get_binding
    binding
  end

  def run_erb
    puts "Value of blah: #{@blah}"
    string = ERB.new(@temp_str).result(get_binding)
    puts string 
    @blah += 1
  end
end

t = Testing.new
t.run_erb
t.run_erb
t.run_erb
t.run_erb
t.run_erb

