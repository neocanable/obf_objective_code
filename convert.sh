#!/bin/bash

# change png file's md5
files=$(find ./ | grep png | grep -v '.bundle')
for i in $files
do
  echo $i;
  if [ ! -d "tmp" ]; then
    mkdir tmp
  fi
  convert $i -quality 99 tmp/tmp.png
  mv tmp/tmp.png $i
done
