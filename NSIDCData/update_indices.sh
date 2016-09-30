#!/bin/sh
# get sea ice indices from NSIDC and convert to my data type

base=ftp://sidads.colorado.edu/DATASETS/NOAA/G02135/

m=0
while [ $m -lt 12 ]
do
    m=$((m+1))
    if [ $m -lt 10 ]; then
	mo=0$m
    else
	mo=$m
    fi
    case $mo in
	01) mon=Jan;;
	02) mon=Feb;;
	03) mon=Mar;;
	04) mon=Apr;;
	05) mon=May;;
	06) mon=Jun;;
	07) mon=Jul;;
	08) mon=Aug;;
	09) mon=Sep;;
	10) mon=Oct;;
	11) mon=Nov;;
	12) mon=Dec;;
	*) echo error ncdwjloky47e;exit -1;;
    esac

    echo -n "$mon "
    wget -q -N $base/$mon/N_${mo}_area_v2.txt
    wget -q -N $base/$mon/S_${mo}_area_v2.txt
done

make txt2dat
./txt2dat

$HOME/NINO/copyfilesall.sh ?_ice_extent.dat ?_ice_area.dat
