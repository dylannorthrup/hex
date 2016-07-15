#!/bin/bash

RBOUT='../set_uuids.rb'

echo '#!/usr/bin/env ruby' > $RBOUT
echo 'module Hex' >> $RBOUT
echo '  class Card' >> $RBOUT
echo '    @@uuid_to_set = {' >> $RBOUT

for f in $(ls CardSetTemplate/CardSetTemplate*); do
  UUID=$(awk -F\" '/m_Guid/ {print $4}' $f)
  NAME=$(awk -F\" '/m_Name/ {print $4}' $f)
  echo "      '$UUID' => '$NAME'," >> $RBOUT
done
echo '    }' >> $RBOUT
echo "    @@uuid_to_set.default = 'None_Defined'" >> $RBOUT
echo "  end" >> $RBOUT
echo "end" >> $RBOUT

echo Your file
cat $RBOUT
