#!/bin/sh
file=rutgers-monthly-snow.mtx
cp $file.gz $file.gz.old
wget -N --user=knmi --password=bIr19pFS http://climate.rutgers.edu/snowcover/files/$file.gz
cmp $file.gz $file.gz.old
if [ $? != 0 ]; then
    gunzip -c $file.gz > $file
    ./polar2grads
    $HOME/NINO/copyfiles.sh snow_rucl.???
fi
