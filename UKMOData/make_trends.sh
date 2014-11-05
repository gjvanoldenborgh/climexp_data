#!/bin/sh
for field in temp salt # sigma # stabi 
do

    for yrbeg in 1985 # 1975 1980 1985 1990
    do
	echo y  | correlatefield ${field}_zonalmean.nc ../KNMIData/time12.dat begin $yrbeg end 2009 trend_${field}_zonalmean_$yrbeg.ctl
	echo y | getmomentsfield ${field}_zonalmean.nc mean begin $yrbeg end 2009 mean_${field}_zonalmean_$yrbeg.ctl
	if [ $field = temp -o $field = salt ]; then
	    echo y  | correlatefield ${field}_sfc.nc ../KNMIData/time12.dat begin $yrbeg end 2009 trend_${field}_sfc_$yrbeg.ctl
	    echo y | getmomentsfield ${field}_sfc.nc mean begin $yrbeg end 2009 mean_${field}_sfc_$yrbeg.ctl

	fi
    done
done
