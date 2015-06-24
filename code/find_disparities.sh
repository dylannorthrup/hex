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
let "AVG_PRICE=${TOTAL_PRICE}/${TOTAL_BOOSTERS}"

echo "Calculated value of 1 Plat is ${AVG_PRICE} gold" > $SNAME
echo "" >> $SNAME
sort -n $ONAME >> $SNAME
