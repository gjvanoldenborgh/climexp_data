#!/bin/sh
# get sea ice indices from NSIDC and convert to my data type

base=ftp://sidads.colorado.edu/DATASETS/NOAA/G02135/
version=v3.0
m=0
while [ $m -lt 12 ]
do
    m=$((m+1))
    if [ $m -lt 10 ]; then
	    mo=0$m
    else
	    mo=$m
    fi

    wget -q -N $base/north/monthly/data/N_${mo}_extent_$version.csv
    wget -q -N $base/south/monthly/data/S_${mo}_extent_$version.csv
done

make txt2dat
./txt2dat $version

$HOME/NINO/copyfilesall.sh ?_ice_extent.dat ?_ice_area.dat
