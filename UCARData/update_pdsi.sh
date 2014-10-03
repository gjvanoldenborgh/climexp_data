#!/bin/sh

###wget -N ftp://ftp.cdc.noaa.gov/Datasets/dai_pdsi/pdsi.mon.mean.nc
file=pdsisc.monthly.maps.1850-2010.fawc=1.r2.5x2.5.ipe=2.nc
wget -N http://www.cgd.ucar.edu/cas/catalog/climind/$file.gz
gunzip -c $file.gz > $file
ncatted -a units,lon,a,c,"degrees_east" -a units,lat,a,c,"degrees_north" \
	-a axis,lon,a,c,"X" -a axis,lat,a,c,"Y" \
	-a units,time,a,c,"years since 0000-01-01 0:00" \
	-a units,sc_PDSI_pm,a,c,"1" $file

$HOME/NINO/copyfiles.sh pdsi.mon.mean.nc $file
