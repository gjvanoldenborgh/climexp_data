#!/bin/sh
file=QBO_1500_2300.txt
levels=`fgrep YEAR $file | cut -f 3- | tr -d '\r'`
i=0
for level in $levels
do
    series=qbo_$level.dat
    cat <<EOF >$series
# QBO at $level hPa
# From Stefan Brönnimann, Reconstructing the quasi-biennial oscillation back to the early 1900s, DOI:10.1029/2007GL031354
# QBO$level [m/s] zonal wind speed
EOF
    cat $file | awk "{print \$1 \" \" \$2 \" \" \$$((3+i))}" | fgrep -v YEAR >> $series
    i=$((i+1))
done