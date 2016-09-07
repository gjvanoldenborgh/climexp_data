#!/bin/sh
if [ "$1" = force ]; then
    force=true
else
    force=false
fi
base=ftp://ftp.chg.ucsb.edu/pub/org/chg/products/CentennialTrends
file=CenTrends_v1_monthly.nc
cp $file $file.old
wget -q -N $base/$file
cmp $file $file.old
if [ $? != 0 -o $force = true ]; then
    cdo -r -f nc4 -z zip -selvar,precip -settaxis,1900-01-15,0:00,1month $file CenTrends_v1_monthly_ce.nc
else
    mv $file.old $file
fi
$HOME/NINO/copyfiles.sh CenTrends_v1_monthly_ce.nc