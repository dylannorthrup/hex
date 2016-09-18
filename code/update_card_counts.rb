#!/usr/bin/env ruby
#
# Take 'collection.out' data and print out name, count, rarity and shard information

$: << "/home/docxstudios/web/hex/code"
require 'Hex'
require "pry"

out_dir = "/home/docxstudios/web/hex"

# step 0: Figure out if collection data is new
if File.mtime('/home/docxstudios/web/hex/code/collection.out') < File.mtime('/home/docxstudios/web/hex/aom_counts.txt') then
  exit
end

# step 1: Read in collection file
counts = Hash.new
File.readlines('/home/docxstudios/web/hex/code/collection.out').map { |line|
  next unless line =~ /^(.*) : (\d+) : (\d+)$/
  counts[$1] = $2
}

# step 2: get card data from database
sets = { 'Shards of Fate' => 'sof', 'Shattered Destiny' => 'sd', 'Armies of Myth' => 'aom', 'Set01_PvE%' => 'pve', 'PvE%Universal_Card_Set' => 'coe1', 'Primal Dawn' => 'primaldawn', 'Herofall' => 'herofall' }
rarities = [ 'Epic', 'Legendary', 'Rare', 'Uncommon', 'Common' ]

# Step 3: merge this information and print it out
sets.each_pair { |set, name|
  out_string = ""
  rarities.each { |rarity|
    foo = Hex::Collection.new
    con = foo.get_db_con
    foo.load_collection_from_search(con, "set_id like '#{set}' and rarity like '#{rarity}' and type not like 'Equipment' order by name asc")
#    binding.pry
    foo.cards.each { |c| 
      c.color = "Artifact" if c.color =~ /Colorless/
      if counts[c.uuid].nil? then
        counts[c.uuid] = "0"
      end
      out_string += "\"#{c.name}\",#{counts[c.uuid]},\"#{c.rarity}\",\"#{c.color}\"\n" 
    }
  }
  fname = out_dir + "/" + name + "_counts.txt"
  fout = File.write(fname, out_string)
}

