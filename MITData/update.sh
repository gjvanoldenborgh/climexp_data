#!/bin/sh
cp tcdata.zip tcdata_old.zip
wget -N ftp://texmex.mit.edu/pub/emanuel/HURR/tracks_netcdf/tcdata.zip
cmp tcdata.zip tcdata_old.zip
[ $? = 0 ] && exit
yr=`date +%Y`
sed -e "s/YYYY/$yr/" tc2grads.F.in > tc2grads.F
make tc2grads
./tc2grads
$HOME/NINO/copyfiles.sh *.dat *.ctl *.grd.gz
