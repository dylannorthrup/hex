#!/bin/bash
#
# Take in new gamedata file and do massaging and processing of it to whip it into a shape appropriate for data extraction

#set -x

if [ ! -f gamedata ]; then
  echo "No gamedata file present. Make sure you copy a new one up here before running again. Exiting"
  exit 1
fi

# Extract text from gzip'd file
if [ ! -f gd.json ] || [ gamedata -nt gd.json ]; then
  echo Looks like we have a new gamedata file. Extracting things out
  if [ -f gd.json ]; then
    rm gd.json
  fi
  for i in $(ls gamedata*); do 
    gzip -dc $i >> gd.json
  #  rm -f processed_$i
  #  mv $i processed_$i
  done

  # Get rid of any pre-existing directories so we start with a blank slate
  ls -d ./[A-Z]* 2> /dev/null 1> /dev/null
  if [ $? -eq 0 ]; then
    echo Removing all old directories
    for f in $(ls -d ./[A-Z]*); do
      echo removing $f
      if [ -d "$f" ]; then
        rm -rf $f
      fi
    done
  fi
  # Split up gd.json into component directories and files
  ./split.sh

  # Getting rid of 'all' directory
  if [ -d all ]; then
    rm -rf all
  fi
  # Process all of the pesudo-json files into real json files in the new directories
  for i in $(ls ./[A-Z]*); do 
    if [ -d $i ]; then 
      echo Doing jsonify on $i 
      ./jsonify_directory.pl $i
    fi
  done
fi

# Extract set IDs from CardSetTemplate files
./gen_set_uuids.sh

# Not sure why I'm doing this here.... need to figure out where these are used
echo "Generating Champion and Card UUID lookup files"
./gen_champs_and_uid_file.sh
./gen_name_and_uid_file.sh

mkdir -p all/CardDefinitions
# Now, copy the new jsonified stuff into a directory that we can point to later
echo "Linking CardTemplate files to central directory"
filter='"m_EquipmentModifiedCard" : 0,'
for file in $(grep -l "$filter" CardTemplate/* | egrep -v 'section_split_file'); do
  name=$(basename $file)
  #cp $file all/CardDefinitions/$name.json
  ln $file all/CardDefinitions/$name.json
done
echo "Linking InventoryItemdata files to central directory"
for file in $(ls InventoryItemData/* | egrep -v 'section_split_file'); do
  name=$(basename $file)
  #cp $file all/CardDefinitions/$name.json
  ln $file all/CardDefinitions/$name.json
done
echo "Linking ChampionTemplate files to central directory"
for file in $(ls ChampionTemplate/* | egrep -v 'section_split_file'); do
  name=$(basename $file)
  #cp $file all/CardDefinitions/$name.json
  ln $file all/CardDefinitions/$name.json
done

echo "All files inside the 'all' directory. Massaging the JSON in there."
./jsonify_directory.pl all/CardDefinitions/

echo "Generating SQL file"
./mk_set_sql.rb all > all.sql
