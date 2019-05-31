#!/bin/bash
for var in t2m sst t2msst
do

	if [ $var = t2msst ]; then
		if [ \( ! -s merra_t2msst.nc \) -o merra_t2msst.nc -ot merra_t2m.nc ]; then
			grads -b -l <<EOF
sdfopen merra_t2m.nc
sdfopen merra_ts.nc
sdfopen lsmask.nc
sdfopen merra_ci.nc
set t 1 last
set x 1 512
define t2msst = t2m.1*lsmask.3(t=1) + ((1-const(ci.4,0,-u))*const(ts.2,0,-u)+const(ci.4,0,-u)*t2m.1)*(1-lsmask.3(t=1))
set sdfwrite merra_t2msst.nc
sdfwrite t2msst
clear sdfwrite
EOF
			cdo -b 32 -r settaxis,1979-01-01,0:00,1mon merra_t2msst.nc aap.nc
			mv aap.nc merra_t2msst.nc
			ncatted -a units,t2msst,a,c,"K" merra_t2msst.nc
		fi
	fi

	case $var in
		t2msst) areas="gl nh sh arctic antarctic";;
		t2m) areas="gl nh sh land sea seaice_n seaice_s landnoice seanoice arctic antarctic";;
		sst) areas="gl nh sh sea seanoice";;
		*) echo error udwiogfewjh; exit -1;;
	esac
	for area in $areas
	do
		case $area in
			gl|land|sea) lats="-90 90";;
			nh) lats="0 90";;
			sh) lats="-90 0";;
			landnoice|seanoice) lats="-60 60";;
			arctic|seaice_n) lats="60 90";;
			antarctic|seaice_s) lats="-90 -60";;
			*) echo "error ouw764w28ye"; exit -1;;
		esac
		case $area in
			land*) landsea=5lan;;
			sea*) landsea=5sea;;
			*) landsea=all
		esac
		series=merra_${var}_$area.dat
		if [ \( ! -s merra_${var}_$area.dat \) -o merra_${var}_$area.dat -ot merra_${var}.nc ]; then
			echo "Generating $series"
			get_index merra_${var}.nc 0 360 $lats lsmask lsmask.nc $landsea standardunits > $series
			if [ $? != 0 ]; then
				rm $series
				echo "%0: error: something went wrong"
				exit -1
			fi
		fi
#		if [ \( ! -s nonmissing_merra_${var}_$area.dat \) -o nonmissing_merra_${var}_$area.dat -ot nonmissing_merra_${var}.nc ]; then
#			get_index nonmissing_merra_${var}.nc 0 360 $lats lsmask lsmask.nc $landsea standardunits > nonmissing_$series
#			if [ $? != 0 ]; then
#				rm nonmissing_$series
#				echo "%0: error: something went wrong"
#				exit -1
#			fi
#		fi
	done
done
