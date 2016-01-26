#!/usr/bin/env ruby
#
# Hex card utility module

module Hex
  require "json"
  require "erb"
  require "mysql"
  require 'pry'

  class Card
    attr_accessor :name, :card_number, :set_id, :faction, :socket_count, :color, :cost, :threshold
    attr_accessor :type, :sub_type, :atk, :health, :text, :flavor, :rarity, :restriction, :artist
    attr_accessor :equipment, :equipment_string, :enters_exhausted, :card_json, :uuid, :htmlcolor
    # Mapping of sets to set names/numbers
    @@uuid_to_set = {
      'f8e55e3b-11e5-4d2d-b4f5-fc72c70dabb5' => 'DELETE',
      'd552850f-2d3c-479c-b120-c9814a0b042a' => 'DELETE',
      '0382f729-7710-432b-b761-13677982dcd2' => '001',
      'b05e69d2-299a-4eed-ac31-3f1b4fa36470' => '002',
      'd8ee3b8d-d4b7-4997-bbb3-f00658dbf303' => 'PVE001',
      'fce480eb-15f9-4096-8d12-6beee9118652' => '003',
      'dacf5a9d-4240-4634-8043-2531365edd83' => 'PVE001AI',
      '3cc27cc9-b3af-44c7-a5de-4126f78d96ed' => 'PVE002',
      'c363c22e-1c03-43c0-a5d3-e3e8759120e7' => 'COE001',
    }

    # Something to translate gem names into HTML colors
    @@gem_to_color = {
      'Colorless' => 'Burlywood',
      'Sapphire'  => 'LightSkyBlue',
      'Ruby'      => '#F5A9A9',
      'Diamond'   => 'White',
      'Wild'      => '#81F781',
      'Blood'     => '#F781F3'
    }

    def initialize(path=nil)
      return if path.nil?
      if path.instance_of? String
        load_card_from_json(path)
      elsif path.instance_of? Array
        @set_id = path[0]
        @card_number = path[1]
        @name = path[2]
        @rarity = path[3].gsub(/Land/, 'Non-Collectible')
        @color = path[4]
        @type = path[5]
        @sub_type = path[6]
        @faction = path[7]
        @socket_count = path[8]
        @cost = path[9]
        @atk = path[10]
        @health = path[11]
        @text = path[12]
        @flavor = path[13]
        @restriction = path[14]
        @artist = path[15]
        @enters_exhausted = path[16]
        @uuid = path[17]
        @threshold = path[18]
        @equipment_string = path[19]
        @curr_resources = path[20]
        @max_resources = path[21]
        @htmlcolor = gem_to_htmlcolor(@color)
      elsif path.instance_of? Mysql
        load_card_from_mysql(path)
      else
        throw Exception("CANNOT INITIALIZE CARD FROM WHAT WE WERE GIVEN")
      end
    end

    def get_db_con
      pw = File.open("/home/docxstudios/hex.sql.pws").read.chomp
      con = Mysql.new 'mysql.doc-x.net', 'hex_reader', pw, 'hex_tcg'
    end

    def get_binding
      binding
    end

    def determine_card_restrictions(unl=nil, unq=nil)
      return 'Unlimited' if unl == "1"
      return 'Unique' if unq == "1"
      return ''
    end

    def setuuid_to_setname(uuid=nil)
      return "UNSET" if uuid.nil?
      return @@uuid_to_set[uuid] unless @@uuid_to_set[uuid].nil?
      return uuid
    end

    def gem_to_htmlcolor(gem=nil)
      return "white" if gem.nil?
      return @@gem_to_color[gem] unless @@gem_to_color[gem].nil?
      return "#D8CEF6" if gem =~ /, /;
      return "white"
    end

    def chomp_string(string)
      string.to_s.gsub(/^\s+/, '').gsub(/\s+$/, '')
    end

    def get_json_value(json, param)
      chomp_string(json[param])
    end

    def get_champion_abilities(json)
      ret_string = json['m_AbilitySlot1']['m_Guid']
      unless json['m_AbilitySlot2']['m_Guid'].match('00000000-0000-0000-0000-000000000000') then
        ret_string = "#{ret_string}, #{json['m_AbilitySlot2']['m_Guid']}"
      end
      unless json['m_AbilitySlot3']['m_Guid'].match('00000000-0000-0000-0000-000000000000') then
        ret_string = "#{ret_string}, #{json['m_AbilitySlot3']['m_Guid']}"
      end
      return ret_string
    end
    
    # Make the card load up from a file
    def load_card_from_json(path=nil)
      return if path.nil?
#      puts "Loading #{path} from json"
      @card_json        = JSON.parse(IO.read(path))
      # Test if this is a Champion
      if @card_json['_v'][0]['ChampionTemplate'].nil? then
        # Not a Champion
        @type           = get_json_value(@card_json, 'm_CardType').gsub(/Action$/, ' Action').gsub(/\|/, ", ")
        @sub_type       = get_json_value(@card_json, 'm_CardSubtype')
        @health         = get_json_value(@card_json, 'm_BaseHealthValue') 
        @rarity         = get_json_value(@card_json, 'm_CardRarity').gsub(/Land/, 'Non-Collectible')
        @color          = get_json_value(@card_json, 'm_ColorFlags').gsub(/\|/, ', ')
      else
        # A Champion
        @type           = "Champion"
        @sub_type       = get_json_value(@card_json, 'm_SubType')
        @health         = get_json_value(@card_json, 'm_BaseHealth')
        @rarity         = 'Champion'
        @color          = 'Colorless'
        @equipment        = get_champion_abilities(@card_json)
        @equipment_string = equipment_string_from_array(@equipment)
      end
      @name             = get_json_value(@card_json, 'm_Name')
      @card_number      = get_json_value(@card_json, 'm_CardNumber')
      if @card_json['m_SetId'].nil? then
        @set_id           = 'UNSET'
      else
        @set_id           = setuuid_to_setname(@card_json['m_SetId']['m_Guid'])
      end
      @uuid             = chomp_string(@card_json['m_Id']['m_Guid'])
      @faction          = get_json_value(@card_json, 'm_Faction')
      @socket_count     = get_json_value(@card_json, 'm_SocketCount')
      @htmlcolor        = gem_to_htmlcolor(@color)
      @cost             = get_json_value(@card_json, 'm_ResourceCost')
      if get_json_value(@card_json, 'm_VariableCost') =~ /1/
        @cost = "#{@cost}X"
      end
      @atk              = get_json_value(@card_json, 'm_BaseAttackValue')
      @text             = get_json_value(@card_json, 'm_GameText')
      @flavor           = get_json_value(@card_json, 'm_FlavorText')
      @restriction      = determine_card_restrictions(get_json_value(@card_json, 'm_Unlimited'), get_json_value(@card_json, 'm_Unique'))
      @artist           = get_json_value(@card_json, 'm_ArtistName')
      @enters_exhausted = get_json_value(@card_json, 'm_EntersPlayExhausted')
      @curr_resources   = get_json_value(@card_json, 'm_CurrentResourcesGranted')
      @max_resources    = get_json_value(@card_json, 'm_MaxResourcesGranted')
      unless @card_json['m_EquipmentSlots'].nil?
        @equipment        = @card_json['m_EquipmentSlots']
        @equipment_string = equipment_string_from_array(@equipment)
      end
      # Do it this way to double check things exist before trying to access them
      @threshold = ""
      unless @card_json['m_Threshold'].nil?
        @card_json['m_Threshold'].each do |th|
          unless @threshold.match(/^$/) then
            @threshold << ", "
          end
          @threshold << "#{th['m_ThresholdColorRequirement']} #{th['m_ColorFlags']}"
        end
      end
    end

    # Quick print out of card information
    def to_s
      string = "#{@name} [Card #{@card_number} from Set #{@set_id}] #{@rarity} #{@color} #{@type} #{@sub_type}"
    end

    def self.dump_s_header
      string = '<pre>'
    end

    def self.dump_html_card_table_header
      string = ''
    end

    def to_html_card_table
      # Set up some quick things here that'll get substituted as appropriate later on
      # By default, the image will span 6 rows
      info_rows = 6
      # If it's a troop, we'll add ATK and Health
      if @type =~ /Troop/
        health_info = "<tr>\n<td>ATK: #{@atk} - Health: #{@health}</td>\n</tr>"
        info_rows += 1
      else
        health_info = ""
      end
      # If it's a Resource, we remove the cost line
      if @type =~ /Resource/
        cost_info = "<tr>\n<td>[#{@curr_resources}/#{@max_resources}]\n</tr>"
        info_rows -= 1
      else
        cost_info = "<tr>\n<td>Cost: #{@cost}<br>\nThreshold: #{@threshold} </td>\n</tr>"
      end
      # If the flavor's blank, don't print the extra, blank row in the table
      if @flavor =~ /^\s*$/
        flavor_info = ""
        info_rows -= 1
      else
        flavor_info = "<tr>\n<td valign=top><i>#{@flavor}</i></td>\n</tr>"
      end
      # Fill up type_info with each bit of info as needed
      type_info = "<tr>\n<td valign=top>\n#{@type}<br>\n"
      if sub_type !~ /^\s*$/
        type_info += "#{@sub_type}<br>\n"
      end
      if restriction !~ /^\s*$/
        type_info += "#{@restriction}<br>\n"
      end
      type_info += "<p>#{@rarity}</td>\n</tr>"

      # If this card has equipment, let's find out what it is and print out its info
      equipment_info = ""
      if @equipment_string =~ /-/
        # Get a local sql connection so we don't muck up with any other connections that might currently be active
        my_con = get_db_con
        equipment_info = "<tr valign=top><td><table border=1><tr><th colspan=2>Related PVE Equipment</th></tr>\n"
        # Copy to local variable and get rid of commas
        es = @equipment_string
        es.gsub!(/,/, '')
        es.split(/\s+/).each do |equip|
          query = "SELECT name, sub_type, text from cards where uuid = '#{equip}'"
          results = my_con.query(query)
          results.each do |row|
            name = row[0]
            slot = row[1]
            text = row[2]
            equipment_info += "<tr><td align=left><i>Name:</i> #{name}</td><td><i>Slot:</i> #{slot}</td align=left></tr><tr><td colspan=2>#{text}</td></tr>\n"
          end
        end
        # Close the SQL connection now we don't need it
        my_con.close
        # And close the Equipment table off
        equipment_info += "</td></tr></table>\n"
        # Finally, do a quick check for missing equipment on the card....
        unless equipment_info.match(/Slot:/) then
          equipment_info = ""
        end
      end

      image_path = get_image_path

      # Standard card image size
      image_size = "width=400 height=560"

      # But for equipment, we go with a different setup
      if @type == "Equipment" then
        image_size = "height='50%'"
      end

      # Now that we've set that up, fill up 'string' with what we want it to have
      string = <<EOCARD
<br><center> <table width=81% border=1 cellpadding=2 cellspacing=2 bgcolor="#{@htmlcolor}">
<tr>
  <td valign=top>#{@name}</td>
  <td width=30% colspan=2 rowspan=#{info_rows} align=center><img src="#{image_path}" #{image_size}></td>
</tr>
#{cost_info}
#{type_info}
<tr>
  <td valign=top><b>Effects Text:</b><p>#{@text}</td>
</tr>
#{health_info}
#{flavor_info}
#{equipment_info}
</table>
</center>
EOCARD
    end

    def get_image_path
      # Use this as the default
      string = "/hex/images/#{@set_id}/#{@name}.png"
      # But if it's an equipment, mix it up
      if @type == "Equipment" then
        location = @set_id
        if location =~ /^00[123]$/ || location =~ /^PVE00[123]$/ || location =~ /^Unspecified$/ then
          location = 'AOM'
        end
        string = "/hex/images/#{location}_Equipment/#{@name}.png"
      end
      string.gsub!(" ", '%20')
      string.gsub!(":", '')
      return string
    end

    def to_csv
      string = "#{@set_id}|#{@card_number}|#{@name}|#{@rarity}|#{@color}|#{@type}|#{@sub_type}|#{@faction}|#{@socket_count}|#{@cost}|#{@atk}|#{@health}|#{@text}|#{@flavor}|#{@restriction}|#{@artist}|#{@enters_exhausted}|#{@equipment_string}|#{@curr_resources}|#{@max_resources}|#{@uuid}"
    end

    # Put this here so we can keep the table header formate in the same location as the to_csv method (immediately previous
    # to this)
    def self.dump_csv_header
      string = 'SET NUMBER|CARD NUMBER|NAME|RARITY|COLOR|TYPE|SUB TYPE|FACTION|SOCKET COUNT|COST|ATK|HEALTH|TEXT|FLAVOR|RESTRICTION|ARTIST|ENTERS PLAY EXHAUSTED|EQUIPMENT STRING|CURRENT RESOURCES ADDED|MAX RESOURCES ADDED|UUID'
    end

    def to_html_table
      string = "<tr>\n<td>#{@set_id}</td>\n<td>#{@card_number}</td>\n<td>#{@name}</td>\n<td>#{@rarity}</td>\n<td>#{@color}</td>\n<td>#{@type}</td>\n<td>#{@sub_type}</td>\n<td>#{@faction}</td>\n<td>#{@socket_count}</td>\n<td>#{@cost}</td>\n<td>#{@threshold}</td>\n<td>#{@atk}</td>\n<td>#{@health}</td>\n<td>#{@text}</td>\n<td>#{@flavor}</td>\n<td>#{@restriction}</td>\n<td>#{@artist}</td>\n<td>#{@enters_exhausted}</td>\n<td>#{@equipment_string}</td>\n<td>#{@curr_resources}</td>\n<td>#{@max_resources}</td>\n<td>#{@uuid}</td>\n</tr>"
    end

    # Put this here so we can keep the table header formate in the same location as the to_html_table method (immediately previous
    # to this)
    def self.dump_html_table_header
      string = ' <tr> <td>SET NUMBER</td> <td>CARD NUMBER</td> <td>NAME</td> <td>RARITY</td> <td>COLOR</td> <td>TYPE</td> <td>SUB TYPE</td> <td>FACTION</td> <td>SOCKET COUNT</td> <td>COST</td> <td>THRESHOLD</td> <td>ATK</td> <td>HEALTH</td> <td>TEXT</td> <td>FLAVOR</td> <td>RESTRICTION</td> <td>ARTIST</td> <td>ENTERS PLAY EXHAUSTED</td> <td>EQUIPMENT UUIDS</td> <td>CURRENT RESOURCES ADDED</td> <td>MAX RESOURCES ADDED</td> <td>UUID</td> </tr> '
    end

    def equipment_string_from_array(equip)
      equipment_string = ""
      if equip.instance_of? Array
        equip.each { |hash|
          next if hash['m_Guid'].nil?
          next if hash['m_Guid'].match('00000000-0000-0000-0000-000000000000')
          equipment_string += "#{hash['m_Guid']}, "
        }
      end
      equipment_string.gsub!(/, $/, '')
      return equipment_string
    end

    def to_sql
      require 'mysql'
      if @equipment_string.nil?
        @equipment_string = ""
      end
      @parsed_name = @name
      @parsed_name.gsub!(/,/, '')
      string = "REPLACE INTO cards (set_id, card_number, name, rarity, color, type, sub_type, faction, socket_count, cost, atk, health, text, flavor, restriction, artist, enters_exhausted, uuid, threshold, equipment_string, curr_resources, max_resources, parsed_name) values ('#{Mysql.escape_string @set_id}','#{Mysql.escape_string @card_number}','#{Mysql.escape_string @name}','#{Mysql.escape_string @rarity}','#{Mysql.escape_string @color}','#{Mysql.escape_string @type}','#{Mysql.escape_string @sub_type}','#{Mysql.escape_string @faction}','#{Mysql.escape_string @socket_count}','#{Mysql.escape_string @cost}','#{Mysql.escape_string @atk}','#{Mysql.escape_string @health}','#{Mysql.escape_string @text}','#{Mysql.escape_string @flavor}','#{Mysql.escape_string @restriction}','#{Mysql.escape_string @artist}','#{Mysql.escape_string @enters_exhausted}','#{Mysql.escape_string @uuid}','#{Mysql.escape_string @threshold}','#{Mysql.escape_string @equipment_string}','#{Mysql.escape_string @curr_resources}','#{Mysql.escape_string @max_resources}','#{Mysql.escape_string @parsed_name}');"
    end

    # Put this here so we can keep the table creation syntax in the same location as the to_sql method (immediately previous to 
    # this)
    def self.dump_sql_header
      string = "CREATE TABLE IF NOT EXISTS cards(set_id VARCHAR(20), card_number INT, name VARCHAR(50), rarity VARCHAR(15), color VARCHAR(60), type VARCHAR(30), sub_type VARCHAR(30), faction VARCHAR(30), socket_count INT, cost VARCHAR(4), atk INT, health INT, text VARCHAR(400), flavor VARCHAR(400), restriction VARCHAR(30), artist VARCHAR(50), enters_exhausted INT, uuid VARCHAR(72) PRIMARY KEY, threshold VARCHAR(60), equipment_string VARCHAR(90), curr_resources INT, max_resources INT);"
    end
  end

  class Collection
    @@base_dir = "/home/docxstudios/web/hex"
    @@set_dir = "Sets"
    @@card_def_dir = "CardDefinitions"
    @@pic_dir = "Portraits"
    @@price_file = "/home/docxstudios/web/hex/all_prices_csv.txt"
    @local_prices = Array.new

    def get_db_con
      pw = File.open("/home/docxstudios/hex.sql.pws").read.chomp
      con = Mysql.new 'mysql.doc-x.net', 'hex_reader', pw, 'hex_tcg'
    end

    # This is stuff you do when you first create a collection
    def initialize()
      @cards = Array.new
    end

    # Get all the card files for a particular directory
    def get_card_files(directory = nil)
      return if directory.nil?
      Dir.entries(directory).grep(/json$/)
    end

    # show length of card collection
    def size()
      return @cards.length
    end

    def cards()
      @cards
    end

    # Something to get groupings based on card values inside the Collection
    def card_trait_list(attribute=nil, split_character=nil)
      return if attribute.nil?
      trait = attribute.downcase
#      puts "Looking for trait: '#{trait}'"
      entries = Hash.new(0)
      @cards.each do |card|
        key = card.send("#{trait}".to_sym)
#        puts card, key
        if split_character.nil?
          entries[key] += 1
        else
          key.split(/#{split_character}/).each do |thing|
            # Skip uncapitalized non-numeric strings as a quick heuristing way to filter meaningless terms (of, the, for, etc)
            next if thing == thing.downcase unless thing.match(/^\d+$/)  
            entries[thing] += 1
          end
        end
      end
#      puts entries.keys
      return entries.keys.sort {|a, b| 
        if a =~ /^\d+/ and b =~ /^\d+/
          a.to_i <=> b.to_i
        else
          a <=> b
        end 
        }
    end

    # Load information for a specific set
    def load_set(set_name = nil, sql_con = nil)
      return if set_name.nil?
      if sql_con.nil?   # If we don't have a SQL connection, load from JSON files
        path = File.join(@@base_dir, @@set_dir, set_name, @@card_def_dir)
        get_card_files(path).each do |card|
          new_card = Card.new(File.join(path, card))
          if new_card.set_id !~ /DELETE/
          @cards << new_card
          end
        end
      else  # If we DO have a sql connection, load from that
        query = "SELECT * FROM cards where set_id = '#{set_name}'"
        results = sql_con.query(query)
        results.each do |row|
          new_card = Card.new(row)
          @cards << new_card
        end
      end
    end

    # Go into all set directories and load their cards
    def load_collection_from_search(sql_con = nil, search_query = nil)
      query = "SELECT * FROM cards where #{search_query}"
      results = sql_con.query(query)
      results.each do |row|
        new_card = Card.new(row)
        @cards << new_card
      end
    end

    # Go into all set directories and load their cards
    def load_collection(sql_con = nil)
      if sql_con.nil?   # If we don't have a SQL connection, load from JSON files
        path = File.join(@@base_dir, @@set_dir)
        Dir.entries(path).each do |set|
          next if set =~ /^\./
          load_set(set)
        end
      else  # If we DO have a sql connection, load from that
        results = sql_con.query("SELECT DISTINCT set_id FROM cards");
        results.each do |set|
          set_name = set[0]
          load_set(set_name, sql_con)
        end
      end
    end

    def get_local_price_info()
      price_data = open(@@price_file).read
      
      prices = Hash.new
      # We extract out the name, rarity and weighted avg prices for GOLD and PLATINUM
      price_data.each_line do |line|
        bits = line.split('","')
        name = bits[0].gsub(/^"/, '')
        rarity = bits[1]
        plat_ary = bits[2].split(',')
        gold_ary = bits[3].split(',')
        plat_avg = plat_ary[1]
        plat_count = plat_ary[2]
        gold_avg = gold_ary[1]
        gold_count = gold_ary[2]
        prices[name] = Hash.new
        prices[name]['rarity'] = rarity
        prices[name]['plat'] = plat_avg
        prices[name]['pcount'] = plat_count
        prices[name]['gold'] = gold_avg
        prices[name]['gcount'] = gold_count
      end
      @local_prices = prices
    end

    # Get card list
    def get_card_list_from_db(filter=nil)
      return if filter.nil?
      retlist = Array.new
      con = get_db_con
      query = "SELECT name, rarity, set_id, color, type FROM cards WHERE #{filter}"
      lines = con.query(query)
      lines.each do |line|
        card = { 'name' => line[0], 'rarity' => line[1], 'set_id' => line[2], 'color' => line[3], 'type' => line[4] }
        retlist << card
      end
      return retlist
    end
    
    # Make this use get_card_list_from_db (so we reduce redundant code paths)
    # Get card info
    def print_local_price_info_for_set(set_id=nil)
      return if set_id.nil?
      return if @local_prices.nil?
      con = get_db_con
      query = "SELECT name, rarity from cards WHERE set_id regexp '^#{set_id}$' AND rarity REGEXP 'Epic|Legendary|Rare|Uncommon|Common' AND type not like 'Equipment' order by name"
      lines = con.query(query)
      rarities = [ 'Epic', 'Legendary', 'Rare', 'Uncommon', 'Common' ]
      rarities.each { |rarity|
        lines.each do |line|
          if line[1] == rarity; then
            name = "#{line[0]}"
            if rarity == 'Epic'; then
              output_name = "#{name} AA"
            else
              output_name = name
            end
            if @local_prices[line[0]].nil? then
              puts "0,0,#{output_name}"
            else
              puts "#{@local_prices[name]['plat']},#{@local_prices[name]['gold']},#{output_name}"
            end
          end
        end
        # Need to rewind the results to the beginning
        lines.data_seek 0
      }
    end

    def print_local_info_for_cardlist(lines=nil, prices=nil, format=nil)
      return if lines.nil?
      return if prices.nil?
      lines = lines.sort do |a, b|
       a['name'] <=> b['name'] 
      end
      lines.each do |line|
        name = line['name']
        if prices[name].nil?; then
          pavg = pcount = gavg = gcount = 0
        else
          pavg = prices[name]['plat']
          pcount = prices[name]['pcount']
          gavg = prices[name]['gold']
          gcount = prices[name]['gcount']
        end
        if format.nil?; then
          puts "#{name} ... #{pavg} PLATINUM [#{pcount} auctions] ... #{gavg} GOLD [#{gcount} auctions]"
        elsif format == "CSV"; then
          puts "#{pavg},#{gavg},#{name}"
        end
      end
    end

  end
end
