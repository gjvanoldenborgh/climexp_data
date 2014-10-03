#!/bin/sh
base=ftp://ftp.cdc.noaa.gov/Datasets/coads/2degree/enh
for var in sst air wspd uwnd vwnd slp cldc wspd3 upstr vpstr
do
    wget -N -q $base/$var.mean.nc
    wget -N -q $base/$var.nobs.nc
    cdo -r -f nc4 -z zip setmisstoc,0 $var.nobs.nc $var.nobs1.nc
    $HOME/NINO/copyfiles.sh $var.mean.nc $var.nobs1.nc
done
