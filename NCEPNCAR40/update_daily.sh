#!/bin/sh
# give argument "noband" to skip the band pass filtering step for speed
script=$0
if [ "$1" = noband -o ${script%slp.sh} != $script ]; then
    band=false
else
    band=true
fi
if [ "$1" = force ]; then
    force=true
else
    force=false
fi
cdoflags="-r -f nc4 -z zip"

base=ftp://ftp.cdc.noaa.gov/Datasets/ncep.reanalysis.dailyavgs/

for dirvar in surface_gauss/prate.sfc.gauss surface_gauss/air.2m.gauss pressure/hgt
do
	dir=`dirname $dirvar`
	var=`basename $dirvar`
	oldhead=`ls -t $var.????.nc | head -1`
	cp $oldhead $oldhead.old
	wget -q -N $base/$dirvar.*.nc
	head=`ls -t $var.????.nc | head -1`
	cmp $head $oldhead.old
	if [ $? != 0 -o $force = true ]; then
		if [ $dir = surface -o $dir = surface_gauss ]; then
		    files=
		    for file in $var.????.nc; do
		        yr=${file%.nc}
		        yr=${yr#${var}.}
		        if [ $yr -ge 2014 ]; then
		            newfile=${file%.nc}_patched.nc
		            if [ ! -s $newfile -o $file -nt $newfile ]; then
    		            ncks -O -x -v time_bnds $file $newfile
    		        fi
		            file=$newfile
		        fi
		        files="$files $file"
		    done
			cdo $cdoflags copy $files $var.daily.nc
			$HOME/NINO/copyfiles.sh	$var.daily.nc
		elif [ $dir = pressure ]; then
			for level in 200 500; do
				for file in $var.????.nc; do
					lfile=`echo $file | sed -e "s/$var/$var$level"/`
					if [ ! -s $lfile -o	 $lfile -ot	 $file ]; then
						ncks -O -d level,${level}. -x -v time_bnds $file $lfile
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
