#!/bin/sh

yr=`date +%Y`
yr=$((yr-1))
###wget -N ftp://ftp.cdc.noaa.gov/Datasets/dai_pdsi/pdsi.mon.mean.nc
file=pdsisc.monthly.maps.1850-$yr.fawc=1.r2.5x2.5.ipe=2.nc
wget -N http://www.cgd.ucar.edu/cas/catalog/climind/$file.gz
newfile=pdsisc.monthly.maps.1850-now.fawc=1.r2.5x2.5.ipe=2.nc
gunzip -c $file.gz > $newfile
ncatted -a units,lon,a,c,"degrees_east" -a units,lat,a,c,"degrees_north" \
    -a axis,lon,a,c,"X" -a axis,lat,a,c,"Y" \
    -a units,time,a,c,"years since 0000-01-01 0:00" \
    -a units,sc_PDSI_pm,a,c,"1" $newfile
$HOME/NINO/copyfiles.sh pdsi.mon.mean.nc $newfile
