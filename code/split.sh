#!/bin/bash
#
# Split out monolithic gamedata file into separate files and directories

# Uncompress gamedata file
gzip -dc gamedata > gd.json

# Replace delimiters and split out into sections, then store those into temporary section files
sed -e 's/\$\$\$---\$\$\$/===/; s/\$\$--\$\$/==/;' gd.json | csplit -n2 -f gdsplit -k - '/===/' {99}

# Make a directory for each section and 
for file in $(ls gdsplit*); do
  SECTION=$(head -2 $file | tail -1)
  if [ -d $SECTION ]; then
    mkdir $SECTION
  fi
  sed '1d;2d' $file | csplit -n6 -f "$SECTION/$SECTION" -k - '/==/' {99999}
done

# Now, clean up
rm gd.json gdsplit*
