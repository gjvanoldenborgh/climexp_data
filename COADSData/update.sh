#!/bin/sh
base=ftp://ftp.cdc.noaa.gov/Datasets/coads/2degree/enh
for var in sst air wspd uwnd vwnd slp cldc wspd3 upstr vpstr
do
    wget -N -q $base/$var.mean.nc
    # save some time, only do this if the observations were updated.
    cp $var.nobs.nc $var.nobs.nc.old
    wget -N -q $base/$var.nobs.nc
    cmp $var.nobs.nc $var.nobs.nc.old
    if [ $? != 0 ]; then
        rm $var.nobs.nc.old
        cdo -r -f nc4 -z zip setmisstoc,0 $var.nobs.nc $var.nobs1.nc
    else
        mv $var.nobs.nc.old $var.nobs.nc
    fi
    for file in $var.mean.nc $var.nobs1.nc
        . $HOME/climexp/add_climexp_url_field.cgi
    done
    $HOME/NINO/copyfiles.sh $var.mean.nc $var.nobs1.nc
done
