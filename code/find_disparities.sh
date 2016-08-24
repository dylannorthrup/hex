#!/bin/bash
FNAME='/home/docxstudios/web/hex/all_prices.txt'
ONAME='/home/docxstudios/web/hex/gold_plat_comparisons.txt'
SNAME='/home/docxstudios/web/hex/sorted_gold_plat_comparisons.txt'

cp /dev/null $ONAME
egrep 'PLATINUM.*GOLD' $FNAME | sed -e 's/ \.\.\. / # /' | sort | uniq | while read line; do
  CNAME=$(echo $line | awk -F\# '{print $1}')
  echo $line | sed -e 's/.*\( [0-9]*\) PLATINUM.*\( [0-9]*\) GOLD.*/\1 \2/' | while read i j ; do
    if [ $i -ne 0 ] && [ $j -ne 0 ]; then
      g=$( expr $j / $i )
#      let g=$j/$i
      if [ "${g}" -ne 0 ]; then
        echo "$g gold per plat [${i}p - ${j}g]  => $CNAME" >> $ONAME
      fi
    fi
  done
done

# Figure out avg exchange rate based on Booster Packs
TOTAL_BOOSTERS=$(grep 'Booster' $ONAME | wc -l)
TOTAL_PRICE=0
for price in $(grep 'Booster' $ONAME | awk '{print $1}'); do
  let "TOTAL_PRICE=${TOTAL_PRICE}+${price}"
done
if [ $TOTAL_BOOSTERS -eq 0 ]; then
  # Use a semi-reasonable default if we have data problems
  AVG_PRICE="100"
  # Also bark so we can take a look at this
  echo "When running find_disparities.sh, you did not get any booster packs listed. Might want to look at that."
else
  let "AVG_PRICE=${TOTAL_PRICE}/${TOTAL_BOOSTERS}"
fi

echo "Calculated value of 1 Plat is ${AVG_PRICE} gold" > $SNAME
echo "" >> $SNAME
sort -n $ONAME >> $SNAME
