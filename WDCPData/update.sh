#!/bin/sh
file=nhtemp-moberg2005.txt
wget -N ftp://ftp.ncdc.noaa.gov/pub/data/paleo/contributions_by_author/moberg2005/$file

outfile=moberg2005.dat
egrep "^Moberg et al" $file > $outfile
echo "Ta [celsius] northern hemisphere temperature" >> $outfile
egrep '^[ 0-9][ 0-9][ 0-9][0-9]  ' $file | cut -b 1-15 >> $outfile
