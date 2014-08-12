#!/usr/bin/env ruby
#
# Hex card utility module

module Hex
  require "json"
  require "erb"
  require "mysql"
  require 'pry'

  class Card
    attr_accessor :name, :card_number, :set_id, :faction, :socket_count, :color, :cost, :threshold_color, :threshold_number
    attr_accessor :image_path, :type, :sub_type, :atk, :health, :text, :flavor, :rarity, :restriction, :artist
    attr_accessor :equipment, :equipment_string, :enters_exhausted, :card_json, :uuid, :htmlcolor
    # Mapping of sets to set names/numbers
    @@uid_to_set = {
      'f8e55e3b-11e5-4d2d-b4f5-fc72c70dabb5' => 'DELETE',
      '0382f729-7710-432b-b761-13677982dcd2' => '001',
    }

    # Something to translate gem names into HTML colors
    @@gem_to_color = {
      'Colorless' => 'Burlywood',
      'Sapphire'  => 'LightSkyBlue',
      'Ruby'      => '#FF2217',
      'Diamond'   => 'White',
      'Wild'      => 'OliveDrab',
      'Blood'     => '#CD65A2'
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
        @image_path = path[18]
        @threshold_color = path[19]
        @threshold_number = path[20]
        @equipment_string = path[21]
        @htmlcolor = gem_to_htmlcolor(@color)
      elsif path.instance_of? Mysql
        load_card_from_mysql(path)
      else
        throw Exception("CANNOT INITIALIZE CARD FROM WHAT WE WERE GIVEN")
      end
    end

    def get_binding
      binding
    end

    def determine_card_restrictions(unl=nil, unq=nil)
      return 'Unlimited' if unl == "1"
      return 'Unique' if unq == "1"
      return ''
    end

    def setuid_to_setname(uid=nil)
      return "UNSET" if uid.nil?
      return @@uid_to_set[uid] unless @@uid_to_set[uid].nil?
      return uid
    end

    def gem_to_htmlcolor(gem=nil)
      return "white" if gem.nil?
      return @@gem_to_color[gem] unless @@gem_to_color[gem].nil?
      return "white"
    end

    def chomp_string(string)
      string.to_s.gsub(/^\s+/, '').gsub(/\s+$/, '')
    end

    def get_json_value(json, param)
      chomp_string(json[param])
    end
    
    # Make the card load up from a file
    def load_card_from_json(path=nil)
      return if path.nil?
      @card_json        = JSON.parse(IO.read(path))
      @name             = get_json_value(@card_json, 'm_Name')
      @card_number      = get_json_value(@card_json, 'm_CardNumber')
      @set_id           = setuid_to_setname(@card_json['m_SetId']['m_Guid'])
      @uuid             = chomp_string(@card_json['m_Id']['m_Guid'])
      @faction          = get_json_value(@card_json, 'm_Faction')
      @socket_count     = get_json_value(@card_json, 'm_SocketCount')
      @color            = get_json_value(@card_json, 'm_ColorFlags').gsub(/\|/, ', ')
      @htmlcolor        = gem_to_htmlcolor(@color)
      @cost             = get_json_value(@card_json, 'm_ResourceCost')
      @image_path       = get_json_value(@card_json, 'm_CardImagePath').gsub(/\\/, '/')
      @type             = get_json_value(@card_json, 'm_CardType').gsub(/Action$/, ' Action').gsub(/\|/, ", ")
      @sub_type         = get_json_value(@card_json, 'm_CardSubtype')
      @atk              = get_json_value(@card_json, 'm_BaseAttackValue')
      @health           = get_json_value(@card_json, 'm_BaseHealthValue')
      @text             = get_json_value(@card_json, 'm_GameText')
      @flavor           = get_json_value(@card_json, 'm_FlavorText')
      @rarity           = get_json_value(@card_json, 'm_CardRarity').gsub(/Land/, 'Non-Collectible')
      @restriction      = determine_card_restrictions(get_json_value(@card_json, 'm_Unlimited'), get_json_value(@card_json, 'm_Unique'))
      @artist           = get_json_value(@card_json, 'm_ArtistName')
      @enters_exhausted = get_json_value(@card_json, 'm_EntersPlayExhausted')
      unless @card_json['m_EquipmentSlots'].nil?
        @equipment        = @card_json['m_EquipmentSlots']
        @equipment_string = equipment_string_from_array(@equipment)
      end
      # Do it this way to double check things exist before trying to access them
      @threshold_color  = ""
      @threshold_number = ""
      unless @card_json['m_Threshold'].nil?
        unless @card_json['m_Threshold'][0].nil?
          threshold_stuff   = @card_json['m_Threshold'][0]
          @threshold_color  = chomp_string(threshold_stuff['m_ColorFlags'])
          @threshold_number = chomp_string(threshold_stuff['m_ThresholdColorRequirement'])
        end
      end
    end

    # Quick print out of card information
    def to_s
      string = "#{@name} [Card #{@card_number} from Set #{@set_id}] #{@rarity} #{@color} #{@type} #{@sub_type}"
    end

    def to_card_table
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
        cost_info = ""
        info_rows -= 1
      else
        cost_info = "<tr>\n<td>Cost: #{@cost}<br>\nThreshold: #{@threshold_number} #{@threshold_color} </td>\n</tr>"
      end
      # If the flavor's blank, don't print the extra, blank row in the table
      if @flavor =~ /^\s*$/
        flavor_info = ""
        info_rows -= 1
      else
        flavor_info = "<tr>\n<td valign=top>#{@flavor}</td>\n</tr>"
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

      # Now that we've set that up, fill up 'string' with what we want it to have
      string = <<EOCARD
<center>
<table width=80% border=1 cellpadding=2 cellspacing=2 bgcolor="#{@htmlcolor}"> 
<tr>
  <td valign=top>#{@name}</td>
  <td width=30% colspan=2 rowspan=#{info_rows} align=center><img src="/hex/images/#{@uuid}.png" width=400 height=560></td>
</tr>
#{cost_info}
#{type_info}
<tr>
  <td valign=top><b>Effects Text:</b><p>#{@text}</td>
</tr>
#{health_info}
#{flavor_info}
</table>
</center>
<br>
EOCARD
    end

    def to_csv
      string = "#{@set_id}|#{@card_number}|#{@name}|#{@rarity}|#{@color}|#{@type}|#{@sub_type}|#{@faction}|#{@socket_count}|#{@cost}|#{@atk}|#{@health}|#{@text}|#{@flavor}|#{@restriction}|#{@artist}|#{@enters_exhausted}|#{@equipment_string}|#{@uuid}"
    end

    # Put this here so we can keep the table header formate in the same location as the to_csv method (immediately previous
    # to this)
    def self.dump_csv_header
      string = 'SET NUMBER|CARD NUMBER|NAME|RARITY|COLOR|TYPE|SUB TYPE|FACTION|SOCKET COUNT|COST|ATK|HEALTH|TEXT|FLAVOR|RESTRICTION|ARTIST|ENTERS PLAY EXHAUSTED|EQUIPMENT STRING|UUID'
    end

    def to_html_table
      string = "<tr>\n<td>#{@set_id}</td>\n<td>#{@card_number}</td>\n<td>#{@name}</td>\n<td>#{@rarity}</td>\n<td>#{@color}</td>\n<td>#{@type}</td>\n<td>#{@sub_type}</td>\n<td>#{@faction}</td>\n<td>#{@socket_count}</td>\n<td>#{@cost}</td>\n<td>#{@threshold_color}</td>\n<td>#{@threshold_number}</td>\n<td>#{@atk}</td>\n<td>#{@health}</td>\n<td>#{@text}</td>\n<td>#{@flavor}</td>\n<td>#{@restriction}</td>\n<td>#{@artist}</td>\n<td>#{@enters_exhausted}</td>\n<td>#{@equipment_string}</td>\n<td>#{@uuid}</td>\n</tr>"
    end

    # Put this here so we can keep the table header formate in the same location as the to_html_table method (immediately previous
    # to this)
    def self.dump_html_table_header
      string = ' <tr> <td>SET NUMBER</td> <td>CARD NUMBER</td> <td>NAME</td> <td>RARITY</td> <td>COLOR</td> <td>TYPE</td> <td>SUB TYPE</td> <td>FACTION</td> <td>SOCKET COUNT</td> <td>COST</td> <td>THRESHOLD COLOR</td> <td>THRESHOLD NUMBER</td> <td>ATK</td> <td>HEALTH</td> <td>TEXT</td> <td>FLAVOR</td> <td>RESTRICTION</td> <td>ARTIST</td> <td>ENTERS PLAY EXHAUSTED</td> <td>EQUIPMENT UUIDS</td> <td>UUID</td> </tr> '
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
      string = "INSERT INTO cards values ('#{Mysql.escape_string @set_id}','#{Mysql.escape_string @card_number}','#{Mysql.escape_string @name}','#{Mysql.escape_string @rarity}','#{Mysql.escape_string @color}','#{Mysql.escape_string @type}','#{Mysql.escape_string @sub_type}','#{Mysql.escape_string @faction}','#{Mysql.escape_string @socket_count}','#{Mysql.escape_string @cost}','#{Mysql.escape_string @atk}','#{Mysql.escape_string @health}','#{Mysql.escape_string @text}','#{Mysql.escape_string @flavor}','#{Mysql.escape_string @restriction}','#{Mysql.escape_string @artist}','#{Mysql.escape_string @enters_exhausted}','#{Mysql.escape_string @uuid}','#{Mysql.escape_string @image_path}','#{Mysql.escape_string @threshold_color}','#{Mysql.escape_string @threshold_number}','#{Mysql.escape_string @equipment_string}');"
    end

    # Put this here so we can keep the table creation syntax in the same location as the to_sql method (immediately previous to 
    # this)
    def self.dump_sql_header
      string = "CREATE TABLE IF NOT EXISTS cards(set_id VARCHAR(20), card_number INT, name VARCHAR(50), rarity VARCHAR(15), color VARCHAR(60), type VARCHAR(30), sub_type VARCHAR(30), faction VARCHAR(30), socket_count INT, cost VARCHAR(4), atk INT, health INT, text VARCHAR(400), flavor VARCHAR(400), restriction VARCHAR(30), artist VARCHAR(50), enters_exhausted INT, uuid VARCHAR(72) PRIMARY KEY, image_path VARCHAR(200), threshold_color VARCHAR(60), threshold_number VARCHAR(2), equipment_string VARCHAR(90));"
    end
  end

  class Collection
    @@base_dir = "/home/docxstudios/web/hex"
    @@set_dir = "Sets"
    @@card_def_dir = "CardDefinitions"
    @@pic_dir = "Portraits"

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
  end
end
