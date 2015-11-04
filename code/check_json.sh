#!/bin/bash
#
# Point this at a directory and it'll tell you what, if any, bad json files there are there

DIR=$1
echo Processing directory $DIR
for file in $(ls $DIR/*); do
  echo -n '.'
  python -mjson.tool $file > /dev/null
  if [ $? != 0 ]; then
    echo
    echo File $file is invalid json
  fi
done
echo
