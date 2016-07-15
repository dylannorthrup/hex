#!/usr/bin/env ruby
#
# Take JSON Champion file and dump it's appropriate SQL info

# rows:

require 'json'
#require 'pry'

require_relative 'set_uuid'

## Mapping of sets to set names/numbers
#@uuid_to_set = {
#  'f8e55e3b-11e5-4d2d-b4f5-fc72c70dabb5' => 'DELETE',
#  'd552850f-2d3c-479c-b120-c9814a0b042a' => 'DELETE',
#  '0382f729-7710-432b-b761-13677982dcd2' => '001',
#  'b05e69d2-299a-4eed-ac31-3f1b4fa36470' => '002',
#  'd8ee3b8d-d4b7-4997-bbb3-f00658dbf303' => 'PVE001',
#  'fce480eb-15f9-4096-8d12-6beee9118652' => '003',
#  'dacf5a9d-4240-4634-8043-2531365edd83' => 'PVE001AI',
#  '3cc27cc9-b3af-44c7-a5de-4126f78d96ed' => 'PVE002',
#  'c363c22e-1c03-43c0-a5d3-e3e8759120e7' => 'COE001',
#  '794e37a9-442f-4c02-a26a-8120a87e8a6e' => 'CLASS',
#  'cd112780-7766-44e8-bf3b-4cd269d47e3e' => 'CLASS',
#  'ccde3b6a-3425-4403-b366-dba0e2358fae' => 'SCENARIO',
#  '2d05262c-d7a0-408f-a280-36d206a29344' => '004',
#  'e3217d24-bff4-4159-94bc-4653012a14cd' => 'PVE004',
#  '4f38be98-79e3-404c-ab6f-a68e99fede18' => 'PVE004',
#  '582f8d90-d5e6-41e5-b6f9-5de73de140be' => 'UnreleasedPVE',
#  '52bc1da1-af3c-4df0-8afb-c999c9f6d645' => 'UnreleasedPVE',
#}

@uuid_to_set.each_pair do |k, v|
  puts "K: #{k} => V: #{v}"
end

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
  return if string.nil?
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
    puts "Encountered error parsing JSON in #{path}: #{e.message}"
    exit 1
  end
  @name = get_json_value(@card_json, 'm_Name')
  @parsed_name = @name.gsub(/, /, ' ')
  @text = get_json_value(@card_json, 'm_GameText')
  @type = get_json_value(@card_json, 'm_ChampionType')
  @sub_type = get_json_value(@card_json, 'm_SubType')
  @faction = get_json_value(@card_json, 'm_Faction')
  @health = get_json_value(@card_json, 'm_BaseHealth')
  set_thing = get_json_value(@card_json, 'm_SetId')
  @set_id = set_thing.gsub(/{\"m_Guid\"=>\"/, '').gsub(/\"}/, '')
#  @equipment_type = get_json_value(@card_json, 'm_EquipmentType')
  id = get_json_value(@card_json, 'm_Id')
#  puts "Id is #{id}"
  @uuid = id.gsub(/{\"m_Guid\"=>\"/, '').gsub(/\"}/, '')
  @rarity = get_json_value(@card_json, 'm_Rarity')
end

load_card_from_json(ARGV[0])
#exit unless @type =~ /PvPChampion|Hero/
exit unless @type =~ /PvPChampion/
puts "REPLACE INTO cards (set_id, card_number, name, rarity, color, type, sub_type, faction, socket_count, cost, atk, health, text, flavor, restriction, artist, enters_exhausted, uuid, threshold, equipment_string, curr_resources, max_resources, parsed_name) values ('#{@uuid_to_set[@set_id]}','0','#{escape_string(@name)}','Non-Collectible','Colorless','Champion','#{escape_string(@sub_type)}','#{escape_string(@faction)}','0','0','0','#{@health}','#{escape_string(@text)}','','','','0','#{@uuid}','','','0','0','#{escape_string(@parsed_name)}');"






