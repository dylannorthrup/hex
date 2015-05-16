#!/bin/bash
#
# Grab collection lines from api data we've collected and print out counts for us

APIFILE='api-data'

rm -f all_prices.txt
wget -q http://doc-x.net/hex/all_prices.txt

# grep the 'Collection' lines out of our API data, grab the last of those, sed to turn the
# data into JSON data, pipe that through python's json.tool, get out all the cards, count
# those and shove them into a file
grep '^\["\[\\"Collection\\"' $APIFILE | \
  tail -1 | \
  sed -e 's/\\"/"/g; 
  s/\]\]"\]$/]}/g; 
  s/^\["\["Collection","[^"]*",/{"Collection": /g' | \
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
