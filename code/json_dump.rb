#!/usr/bin/env ruby
#
# Take JSON equipment file and dump it's appropriate SQL info

# rows:

require 'json'
require 'pry'


# Some modules to handle some stuff
def escape_string(str)
  str.gsub(/[\0\n\r\\\'\"\x1a]/) do |s|
    case s
    when "\0" then "\\0"
    when "\n" then "\\n"
    when "\r" then "\\r"
    when "\x1a" then "\\Z"
    else "\\#{s}"
    end
  end
end

def chomp_string(string)
  string.to_s.gsub(/^\s+/, '').gsub(/\s+$/, '')
end

def get_json_value(json, param)
  chomp_string(json[param])
end

def load_card_from_json(path=nil)
  return if path.nil?
  @card_json = JSON.parse(IO.read(path))
  @name = get_json_value(@card_json, 'm_Name')
  @text = get_json_value(@card_json, 'm_Description')
  @type = get_json_value(@card_json, 'm_Type')
  @equipment_type = get_json_value(@card_json, 'm_EquipmentType')
  id = get_json_value(@card_json, 'm_Id')
  @uuid = id.gsub(/{\"m_Guid\"=>\"/, '').gsub(/\"}/, '')
  @rarity = get_json_value(@card_json, 'm_Rarity')
end

load_card_from_json(ARGV[0])
exit unless @type =~ /Equipment/
puts "INSERT INTO cards values ('ArenaEquipment', '0', '#{escape_string(@name)}', '#{escape_string(@rarity)}', 'Equipment', 'Equipment', '#{escape_string(@equipment_type)}', '', 0, 0, 0, 0, '#{escape_string(@text)}', '', '', '', 0, '#{escape_string(@uuid)}', '', '', '', '', 0, 0);"






