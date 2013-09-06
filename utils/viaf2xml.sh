#!/bin/bash
# viaf2xml
# Clean up VIAF cluster dumpr so it is valid xml
FILE=$1
EXTENSION=${FILE##*.}
if [ -f $FILE ]
  then
    if [[ "xml" == $EXTENSION ]] 
    then
      echo "Processing $FILE ...."
      sed -i "s/^[0-9]*//g" $FILE
      sed -i 's/^[ \t]*//;s/[ \t]*$//' $FILE
      sed -i '1s;^;<viafClusters>;' $FILE
      echo "</viafClusters>" >> $FILE
      echo " done."
  fi
fi