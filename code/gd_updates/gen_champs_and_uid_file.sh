#!/bin/bash
#
# Look through CardTemplate files and create a file with a quick lookup table correlating UUIDs to card names

OUTFILE='guid_to_champ.out'

# Clean out OUTFILE first
cp /dev/null $OUTFILE

for file in $(ls ChampionTemplate/*); do
  UUID=$(grep -A 1 'Reckoning.Game.*Template' $file | tail -1 | awk -F\" '{print $4}')
  # Skip if we don't have a proper UUID
  if [ "${UUID}X" == "X" ]; then
    echo "Skipping $file for blank UUID"
    continue
  fi
  # Skip if the UUID is the default
  if [ "${UUID}" == "00000000-0000-0000-0000-000000000000" ]; then
    echo "Skipping $file for default UUID"
    continue
  fi
  NAME=$(awk -F\" '/^"m_Name"/ {print $4}' $file)
  echo $UUID = $NAME >> $OUTFILE
done

echo "Finished generating contents of $OUTFILE. Exiting."
