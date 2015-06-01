#!/bin/bash
#
# Grab card collection data we've gotten from the Hex API and print out counts for us

APIFILE='collection.out'

if [ ! -f $APIFILE ]; then
  echo "*** Did not find a collection file '$APIFILE'."
  echo "*** Cannot work without that."
  echo "*** Exiting."
  exit 1
fi

# If this is called with the 'nodl' option, skip the downloading of new price data
if [ "$1X" == "DEBUGX" ]; then
  echo "Skipping everything because DEBUG"
  exit 0
#  set +x  # Turn off debugging of the script. . . but simply something to have as a placeholder
#          # so the syntax is correct
#  echo "Skipping price data download"
elif [ "$1X" == "nodlX" ]; then
# If this is called with the 'nodl' option, skip the downloading of new price data
  set +x  # Turn off debugging of the script. . . but simply something to have as a placeholder
          # so the syntax is correct
  echo "Skipping price data download"
else
  echo "Downloading price data"
  rm -f all_prices.txt
  wget -q http://doc-x.net/hex/all_prices.txt
fi

#echo "Beginning local data parse"
# This should only be called when a Collection line is in the APIFILE.  Use sed to turn the
# data into JSON data, pipe that through python's json.tool, get out all the cards, count
# those and shove them into a file
sed -e 's/\\"/"/g; 
  s/\]\]"\]$/]}/g; 
  s/^\["\["Collection","[^"]*",/{"Collection": /g' $APIFILE | \
  python -mjson.tool | \
  egrep '^        "' | \
  sed -e 's/",*$//; s/^        "/ - /' | \
  uniq -c | \
  while read card; do
    cardname=$(echo $card | sed -e 's/.* - //; s/,//g')
    stuff=$(grep "^$cardname \.\.\." all_prices.txt | uniq | egrep -v ' AA ' | sed -e 's/\.\.\./-/g; s/\[[0-9]* auctions\]//g')
    count=$(echo "$card" | awk '{print $1}')
    # Filter out standard Shards which aren't in the prices data
    if [ "${stuff}X" == "X" ]; then
      continue
    else 
      echo $count - $stuff 
    fi
  done > price_and_count_data.out
# Add in Booster Pack prices
grep 'Booster Pack' all_prices.txt | \
  while read i; do 
    echo $i | sed -e 's/\.\.\./-/g; s/\[[0-9]* auctions\]//g; s/^/1 - /' 
  done >> price_and_count_data.out;


