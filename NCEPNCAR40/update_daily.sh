#!/bin/sh
# give argument "noband" to skip the band pass filtering step for speed
script=$0
if [ "$1" = noband -o ${script%slp.sh} != $script ]; then
    band=false
else
    band=true
fi
cdoflags="-r -f nc4 -z zip"

base=ftp://ftp.cdc.noaa.gov/Datasets/ncep.reanalysis.dailyavgs/

for dirvar in surface/slp surface_gauss/air.2m.gauss surface_gauss/prate.sfc.gauss pressure/hgt
do
	dir=`dirname $dirvar`
	var=`basename $dirvar`
	oldhead=`ls -t $var.????.nc | head -1`
	cp $oldhead $oldhead.old
	wget -q -N $base/$dirvar.*.nc
	head=`ls -t $var.????.nc | head -1`
	cmp $head $oldhead.old
	if [ $? != 0 ]; then
		if [ $dir = surface -o $dir = surface_gauss ]; then
			cdo $cdoflags copy $var.????.nc $var.daily.nc
			$HOME/NINO/copyfiles.sh	$var.daily.nc
		elif [ $dir = pressure ]; then
			for level in 200 500; do
				for file in $var.????.nc; do
					lfile=`echo $file | sed -e "s/$var/$var$level"/`
					if [ ! -s $lfile -o	 $lfile -ot	 $file ]; then
						ncks -O -d level,${level}. $file $lfile
					fi
				done
				cdo $cdoflags copy $var$level.????.nc $var$level.daily.nc
				if [ "$band" = true ]; then
    				./bandpass_variance $var$level
    			fi
				$HOME/NINO/copyfiles.sh	$var$level.daily.nc $var${level}var.???
			done
		fi
	fi
	rm $oldhead.old
done
