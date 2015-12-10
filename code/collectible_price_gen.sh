#!/bin/bash
#
# Do price generation for all of the collectible price scripts

cd /home/docxstudios/web/hex/code
for script in $(ls *_collectible_prices.rb); do
  ARG=$(echo $script | sed -e 's/.rb$//')
  /home/docxstudios/cron_price_gen.sh $ARG
done

