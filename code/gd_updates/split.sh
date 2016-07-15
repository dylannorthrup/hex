#!/bin/bash
#
# Split out monolithic gamedata file into separate files and directories

# Replace delimiters and split out into sections, then store those into temporary section files
sed -e 's/\$\$\$---\$\$\$/===/; s/\$\$--\$\$/==/;' gd.json | csplit -n2 -f gdsplit -k - '/===/' {99}

# Now that we've got multiple gamedata files, we need to consolidate everything and sort it....
# Make a directory for each section and make a consolidated file with all the contents in it 
# while snipping off the section header info.

# First thing, get rid of all of the section_split_file files.
for ssf in $(ls */section_split_file); do
  echo "Removing $ssf"
  rm $ssf
done

# Now, do the work
for file in $(wc -l gdsplit* | awk '/gdsplit/ && !/ 2 gdsplit/ {print $2}'); do
  SECTION=$(head -2 $file | tail -1 | sed -e 's///')
  echo Removing $SECTION/$SECTION files. 
  echo $SECTION/${SECTION}* | xargs rm -f
  echo Working on making section_split_file for $SECTION. 
  section_file="${SECTION}/section_split_file"
  if [ ! -d $SECTION ]; then
    echo "Making $SECTION directory"
    mkdir $SECTION
    echo "===" > $section_file
    echo "$SECTION" >> $section_file
  fi
  tail -n +3 $file >> $section_file
done

# Now, go ahead and split up those section files for each directory
for file in $(ls */section_split_file); do
  SECTION=$(echo $file | sed -e 's/.section_split_file$//;')
  echo Working on parsing section_split_file for $SECTION.
  echo Slicing up $SECTION
  sed '1d;2d' $file | csplit -n6 -f "$SECTION/$SECTION" -k - '/^==/' {99999}
  # And get rid of the ${SECTION}000000 file since it's inevitably 0 length
  if [ ! -s "${SECTION}/${SECTION}000000" ]; then
    rm ${SECTION}/${SECTION}000000
  fi
done

# Now, clean up
rm gdsplit*

