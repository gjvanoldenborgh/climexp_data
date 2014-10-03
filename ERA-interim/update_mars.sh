#!/bin/sh
if [ "$1" = force ]; then
	force=true
	download=false
fi
c=`ecls | wc -l`
if [ $c -lt 2 ]; then
	echo "Make sure you are logged in with eccert"
	exit -1
fi

if [ "$download" != false ]; then
	echo "submit MARS job to retrieve ERA-interim fields"
	ecjput ecgate marsjob.sh
	
	echo "wait for it to finish"
	c=1
	while [ $c = 1 ]
	do
		sleep 60
		c=`ecjls|fgrep -c EXEC`
	done
fi

echo "retrieve output"
vars=`fgrep "for var in t2m " marsjob.sh | sed -e "s/for var in //"`
for var in $vars
do
  if [ $var != "#" ]; then
	if [ ! -s eraint_${var}.grb ]; then
		echo "ecget eraint_${var}.grb"
		ecget eraint_${var}.grb
	fi
	if [ force=true -o ! -s eraint_${var}.nc -o eraint_${var}.nc -ot eraint_${var}.grb ]; then
		echo "converting $var to netcdf"
		cdo -r -R -f nc copy eraint_${var}.grb eraint_${var}.nc
		. ./gribcodes.sh
		ncrename -O -v var$par,$var eraint_${var}.nc aap.nc
		ncatted -O -a long_name,$var,a,c,"$long_name" \
				   -a units,$var,a,c,"$units" \
				   -a axis,lon,a,c,"x" -a axis,lat,a,c,"y" \
				   -a title,global,a,c,"ERA-interim reanalysis" \
			 aap.nc eraint_${var}.nc
		$HOME/NINO/copyfiles.sh eraint_${var}.nc
	fi
  fi
done

vars=`fgrep "for var in pr " marsjob.sh | sed -e "s/for var in //"`
for var in $vars
do
  if [ $var != "#" ]; then
	for step in 12 24
	do
		if [ ! -s eraint_${var}_$step.grb ]; then
			echo "ecget eraint_${var}_$step.grb"
			ecget eraint_${var}_$step.grb
		fi
	done
	if [ force = true -o ! -s eraint_${var}.nc -o eraint_${var}_$step.nc -ot eraint_${var}_24.grb ]; then
		echo "adding and converting $var to netcdf"
		cdo -r -R -f nc add eraint_${var}_12.grb eraint_${var}_24.grb aap.nc
		. ./gribcodes.sh
		cdo -r -R -f nc divc,$fac aap.nc eraint_${var}.nc
		ncrename -O -v var$par,$var eraint_${var}.nc aap.nc
		ncatted -O -a long_name,$var,a,c,"$long_name" \
				   -a units,$var,a,c,"$units" \
				   -a axis,lon,a,c,"x" -a axis,lat,a,c,"y" \
				   -a title,global,a,c,"ERA-interim reanalysis" \
			 aap.nc eraint_${var}.nc
		$HOME/NINO/copyfiles.sh eraint_${var}.nc
	fi
  fi
done

cdo -r add eraint_pr.nc eraint_evap.nc eraint_pme.nc
$HOME/NINO/copyfiles.sh eraint_pme.nc
