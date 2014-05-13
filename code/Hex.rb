#!/usr/local/opt/ruby/bin/ruby
#
# Hex card utility module

module Hex
  require "json"

  class Card
    attr_accessor :name, :card_number, :set, :faction, :socket_count, :color, :cost, :threshold_color, :threshold_number
    attr_accessor :image_path, :type, :sub_type, :atk, :health, :text, :flavor, :rarity, :unlimited, :unique, :artist
    attr_accessor :equipment, :enters_exhausted, :card_json
    # Mapping of sets to set names/numbers
    @@uid_to_set = {
      'f8e55e3b-11e5-4d2d-b4f5-fc72c70dabb5' => 'DELETE',
      '0382f729-7710-432b-b761-13677982dcd2' => '001',
    }

    def initialize(path=nil)
      return if path.nil?
      load_card(path)
    end

    def setuid_to_setname(uid=nil)
      return "UNSET" if uid.nil?
      return @@uid_to_set[uid] unless @@uid_to_set[uid].nil?
      return uid
    end
    
    # Make the card load up from a file
    def load_card(path=nil)
      return if path.nil?
      @card_json        = JSON.parse(IO.read(path))
      @name             = @card_json['m_Name']
      @card_number      = @card_json['m_CardNumber']
      @set              = setuid_to_setname(@card_json['m_SetId']['m_Guid'])
      @faction          = @card_json['m_Faction']
      @socket_count     = @card_json['m_SocketCount']
      @color            = @card_json['m_ColorFlags']
      @cost             = @card_json['m_ResourceCost']
      @image_path       = @card_json['m_CardImagePath'].gsub(/\\/, '/')
      @type             = @card_json['m_CardType']
      @sub_type         = @card_json['m_CardSubtype']
      @atk              = @card_json['m_BaseAttackValue']
      @health           = @card_json['m_BaseHealthValue']
      @text             = @card_json['m_GameText']
      @flavor           = @card_json['m_FlavorText']
      @rarity           = @card_json['m_CardRarity']
      @unlimited        = @card_json['m_Unlimited']
      @unique           = @card_json['m_Unique']
      @artist           = @card_json['m_ArtistName']
      @equipment        = @card_json['m_EquipmentSlots']
      @enters_exhausted = @card_json['m_EntersPlayExhausted']
      # Do it this way to double check things exist before trying to access them
      unless @card_json['m_Threshold'].nil?
        unless @card_json['m_Threshold'][0].nil?
          threshold_stuff   = @card_json['m_Threshold'][0]
          @threshold_color  = threshold_stuff['m_ColorFlags'] 
          @threshold_number = threshold_stuff['m_ThresholdColorRequirement'] 
        end
      end
    end

    # Quick print out of card information
    def to_s
      string = "#{@name} [Card #{@card_number} from Set #{@set}] #{@rarity} #{@color} #{@type} #{@sub_type}"
    end

    def to_csv
      string = "#{@set}|#{@card_number}|#{@name}|#{@rarity}|#{@color}|#{@type}|#{@sub_type}|#{@faction}|#{@socket_count}|#{@cost}|#{@atk}|#{@health}|#{@text}|#{@flavor}|#{@unlimited}|#{@unique}|#{@artist}|#{@image_path}|#{@enters_exhausted}"
    end

    def to_html
#      string =
    end
  end

  class Collection
    @@base_dir = "/home/docxstudios/web/hex"
    @@set_dir = "Sets"
    @@card_def_dir = "CardDefinitions"
    @@pic_dir = "Portraits"

    # This is stuff you do when you first create a collection
    def initialize()
      @cards = Array.new
#      puts "Collection size: #{self.size}"
#      puts "Base directory: #{@@base_dir}"
#      puts "Set directory: #{@@set_dir}"
#      puts "Card Definition directory: #{@@card_def_dir}"
#      puts "Pictures directory: #{@@pic_dir}"
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

    # Load information for a specific set
    def load_set(set_name = nil)
#      puts "Set name: #{set_name}"
      return if set_name.nil?
      path = File.join(@@base_dir, @@set_dir, set_name, @@card_def_dir)
      get_card_files(path).each do |card|
        @cards << Card.new(File.join(path, card))
      end
    end

    # Go into all set directories and load their cards
    def load_collection
      path = File.join(@@base_dir, @@set_dir)
      Dir.entries(path).each do |set|
        load_set(set)
      end
    end
  end
end
