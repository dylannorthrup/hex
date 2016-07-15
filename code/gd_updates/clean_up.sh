#!/bin/bash
#
# Clean up the working directory after we're done with importing stuff

echo Cleaning everything up
if [ -f gd.json ]; then
  echo Removing gd.json
  rm gd.json
fi
if [ -f gamedata ] || [ -f gamedata.gameforge ]; then
  echo Removing gamedata files
  for i in $(ls gamedata*); do 
    rm -f processed_$i
    mv $i processed_$i
  done
fi

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

# Getting rid of 'all' directory
if [ -d all ]; then
  echo Removing 'all' directory
  rm -rf all
fi

if [ -f guid_to_champ.out ] || [ -f guid_to_name ]; then
  echo Removing guid_to_*.out files
  rm guid_to_*.out
fi

echo Done cleaning up.
