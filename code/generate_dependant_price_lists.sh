#!/bin/bash
#
# A wrapper script to run all of the "cron_price_gen.sh" scripts that aren't the 'all_prices_json' script or the 
# 'all_prices_csv' script
# Note: We call 'all_prices_csv' first as other files in the series are dependent on it.

# This will be the list once we've converted some of the other scripts
#for script in all_prices_with_uuids legendary_rare_detailed_price_info legendary_rare_csv legendary_rare_prices common_prices all_prices have-want; do 
for script in all_prices_csv all_prices_with_uuids legendary_rare_csv legendary_rare_prices common_prices all_prices have-want; do 
  /home/docxstudios/cron_price_gen.sh $script
done
