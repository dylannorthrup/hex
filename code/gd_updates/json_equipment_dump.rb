#!/usr/bin/env ruby
#
# Take JSON equipment file and dump it's appropriate SQL info

# rows:

require 'json'
#require 'pry'

require_relative 'set_uuid'

DEBUG=true

# Some modules to handle some stuff
def escape_string(str)
  return if str.nil?
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
  begin
    @card_json = JSON.parse(IO.read(path))
  rescue JSON::ParserError => e
    puts "Had an exception parsing the JSON of #{path}: #{e.message}"
    exit 1
  end
  @type = get_json_value(@card_json, 'm_Type')
#  if @type !~ /Equipment|Gem|CardPack/ then 
#    return
#  end
  @name = get_json_value(@card_json, 'm_Name')
  @parsed_name = @name.gsub(/,/, '')
  @text = get_json_value(@card_json, 'm_Description')
  @equipment_type = get_json_value(@card_json, 'm_EquipmentType')
  @design_notes = get_json_value(@card_json, 'm_DesignNotes')
  set_id = get_json_value(@card_json, 'm_SetId')
  @set_uuid = set_id.gsub(/{\"m_Guid\"=>\"/, '').gsub(/\"}/, '')
  id = get_json_value(@card_json, 'm_Id')
  @uuid = id.gsub(/{\"m_Guid\"=>\"/, '').gsub(/\"}/, '')
  @rarity = get_json_value(@card_json, 'm_Rarity')
end

def doit(path=nil)
  return if path.nil?
  load_card_from_json(path)
  if DEBUG then puts "Name: #{@name}\n\tUUID: #{@uuid}\n\tSet UUID: #{@set_uuid} [#{@uuid_to_set[@set_uuid]}]"; end
  if @type =~ /Equipment/ then
#    release = get_release(@design_notes)
    puts "REPLACE INTO cards values ('#{escape_string(@uuid_to_set[@set_uuid])}', '0', '#{escape_string(@name)}', '#{escape_string(@rarity)}', 'Equipment', 'Equipment', '#{escape_string(@equipment_type)}', '', 0, 0, 0, 0, '#{escape_string(@text)}', '', '', '', 0, '#{escape_string(@uuid)}', '', '', 0, 0, '#{escape_string(@parsed_name)}');"
  elsif @type =~ /Pack/ then
    return unless @text =~ /Booster|Primal/
    puts "REPLACE INTO cards values ('#{escape_string(@uuid_to_set[@set_uuid])}', '1', '#{escape_string(@name)}', '#{escape_string(@rarity)}', 'Artifact', 'Pack', '', '', 0, 0, 0, 0, '#{escape_string(@text)}', '', '', '', 0, '#{escape_string(@uuid)}', '', '', 0, 0, '#{escape_string(@parsed_name)}');"
  elsif @type =~ /Gem/ then
    #puts "REPLACE INTO cards values ('Gem', '1', '#{escape_string(@name)}', '', 'Gem', 'Gem', '', '', 0, 0, 0, 0, '#{escape_string(@text)}', '', '', '', 0, '#{escape_string(@uuid)}', '', '', 0, 0, '#{escape_string(@parsed_name)}');"
    puts "REPLACE INTO cards values ('#{escape_string(@uuid_to_set[@set_uuid])}', '1', '#{escape_string(@name)}', '', 'Gem', 'Gem', '', '', 0, 0, 0, 0, '#{escape_string(@text)}', '', '', '', 0, '#{escape_string(@uuid)}', '', '', 0, 0, '#{escape_string(@parsed_name)}');"
  elsif @type =~ /Sleeve/ then
    puts "REPLACE INTO cards values ('#{escape_string(@uuid_to_set[@set_uuid])}', '1', '#{escape_string(@name)}', '', 'DeckSleeve', 'DeckSleeve', '', '', 0, 0, 0, 0, '#{escape_string(@text)}', '', '', '', 0, '#{escape_string(@uuid)}', '', '', 0, 0, '#{escape_string(@parsed_name)}');"
  elsif @type =~ /CompTicket/ then
    puts "REPLACE INTO cards values ('#{escape_string(@uuid_to_set[@set_uuid])}', '1', '#{escape_string(@name)}', '', 'CompTicket', 'CompTicket', '', '', 0, 0, 0, 0, '#{escape_string(@text)}', '', '', '', 0, '#{escape_string(@uuid)}', '', '', 0, 0, '#{escape_string(@parsed_name)}');"
  elsif @type =~ /Mercenaries/ then
    puts "REPLACE INTO cards values ('#{escape_string(@uuid_to_set[@set_uuid])}', '1', '#{escape_string(@name)}', '', 'Mercenary', 'Mercenary', '', '', 0, 0, 0, 0, '#{escape_string(@text)}', '', '', '', 0, '#{escape_string(@uuid)}', '', '', 0, 0, '#{escape_string(@parsed_name)}');"
  elsif @type =~ /Stardust/ then
    puts "REPLACE INTO cards values ('#{escape_string(@uuid_to_set[@set_uuid])}', '1', '#{escape_string(@name)}', '', 'Stardust', 'Stardust', '', '', 0, 0, 0, 0, '#{escape_string(@text)}', '', '', '', 0, '#{escape_string(@uuid)}', '', '', 0, 0, '#{escape_string(@parsed_name)}');"
  elsif @type =~ /TreasureChest/ then
    puts "REPLACE INTO cards values ('#{escape_string(@uuid_to_set[@set_uuid])}', '1', '#{escape_string(@name)}', '', 'TreasureChest', 'TreasureChest', '', '', 0, 0, 0, 0, '#{escape_string(@text)}', '', '', '', 0, '#{escape_string(@uuid)}', '', '', 0, 0, '#{escape_string(@parsed_name)}');"
  elsif @type =~ /VIPProduct/ then
    puts "REPLACE INTO cards values ('#{escape_string(@uuid_to_set[@set_uuid])}', '1', '#{escape_string(@name)}', '', 'VIPProduct', 'VIPProduct', '', '', 0, 0, 0, 0, '#{escape_string(@text)}', '', '', '', 0, '#{escape_string(@uuid)}', '', '', 0, 0, '#{escape_string(@parsed_name)}');"
  end
end

#@releases = {
#  "AZ1" => "COE001",
#  "Arena" => "PVE001",
#  "Holiday" => "HOLIDAY",
#  "Set 1" => "001",
#  "Set 2" => "002",
#  "Set 3" => "003",
#  "Set 4" => "004",
#  "WOFSET3" => "003",
#  "WheelsOfFate" => "001",
#}
#
#def get_release(notes=nil?)
#  # Set this as default
#  release = 'Unspecified'
#  return release if notes.nil?
#  @releases.each_pair do |k, v|
#    if notes =~ /#{k}/ then
#      return v
#    end
#  end
#  return release
#end

doit(ARGV[0])
#directory=ARGV[0]
#Dir.foreach(directory) do |file|
#  next if file =~ /^\./
#  #puts "#{directory}/#{file}"
#  target = "#{directory}/#{file}"
#  doit(target)
#  #doit(ARGV[0])
#end
