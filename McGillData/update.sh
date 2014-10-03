#!/bin/sh
for var in crop past
do
    wget -N http://www.geog.mcgill.ca/landuse/pub/Data/Histlanduse/NetCDF/gl${var}_1700-2007_0.5.nc.zip
    gunzip -c gl${var}_1700-2007_0.5.nc.zip > gl${var}_1700-2007_0.5.nc
    cdo -r settaxis,1700-06-01,0:00,1year gl${var}_1700-2007_0.5.nc gl${var}_1700-2007_05.nc
done
$HOME/NINO/copyfiles.sh gl*_1700-2007_05.nc
