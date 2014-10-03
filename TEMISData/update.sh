#!/bin/sh
# uit de mail van Marc Allaart
#
base="http://www.temis.nl/protocols/o3field/data"
now=`date "+%Y"`
#
year=1977
while [ $year -lt $now ]
do
	year=$((year + 1))
	if [ $year = 1978 ]; then
		months="11 12"
	else
		months="01 02 03 04 05 06 07 08 09 10 11 12"
	fi
	for month in $months
	do
		file=o3col$year${month}aver.hdf
		for satellite in multimission gome2 # toms_n7 sbuv_noaa9 gome toms_ep sciamachy omi
		do
			if [ $satellite = multimission ]; then
				url=$base/$year/$month/$file
			else
				url=$base/$satellite/$year/$month/$file
			fi
			if [ -s $file ]; then
				wget -q -N $url
			else
				wget -q $url
			fi
		done
		if [ ! -s $file ]; then
			echo "Found data up to $oldfile"
			echo "($url did not exist)"
			. ./hdf2nc.sh
			exit
		fi
		oldfile=$file
	done
done
done
# http://www.temis.nl/protocols/o3field/toms_n7/1978/11/o3col197811aver.hdf
# http://www.temis.nl/protocols/o3field/toms_n7/1978/11/o3col197811aver.hdf
# http://www.temis.nl/protocols/o3field/data/multimission/2008/o3col200812aver.hdf
