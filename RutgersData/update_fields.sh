#!/bin/sh
force=""
[ -n "$1" ] && force=$1
file=rutgers-monthly-snow.mtx
cp $file.gz $file.gz.old
wget -N --user=knmi http://climate.rutgers.edu/snowcover/files/$file.gz
cmp $file.gz $file.gz.old
if [ $? != 0 -o "$force" = force ]; then
    gunzip -c $file.gz > $file
    ./polar2grads
    $HOME/NINO/copyfiles.sh snow_rucl.???
fi
