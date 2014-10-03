#!/bin/sh
for var in t2m sst t2msst 
do

	if [ $var = t2msst ]; then
		if [ \( ! -s erai_t2msst.nc \) -o erai_t2msst.nc -ot erai_t2m.nc ]; then
			grads -b -l <<EOF
sdfopen erai_t2m.nc
sdfopen erai_sst.nc
sdfopen lsmask07.nc
sdfopen erai_ci.nc
set x 1 512
define lsmsst = const(const(sst.2,0),1,-u)
define lsmall = 1 - (1-lsmsst)*(1-lsm.3(t=1))
set t 1 last
define t2msst = t2m.1*lsmall(t=1) + ((1-const(ci.4,0,-u))*const(sst.2,0,-u)+const(ci.4,0,-u)*t2m.1)*(1-lsmall(t=1))
set sdfwrite erai_t2msst.nc
sdfwrite t2msst
clear sdfwrite
EOF
			cdo -b 32 -r settaxis,1979-01-01,0:00,1mon erai_t2msst.nc aap.nc
			mv aap.nc erai_t2msst.nc
			ncatted -a units,t2msst,a,c,"K" erai_t2msst.nc
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
		series=erai_${var}_$area.dat
		if [ \( ! -s erai_${var}_$area.dat \) -o erai_${var}_$area.dat -ot erai_${var}.nc ]; then
			echo "Generating $series"
			get_index erai_${var}.nc 0 360 $lats lsmask lsmask07.nc $landsea standardunits > $series
			if [ $? != 0 -o ! -s $series ]; then
				rm $series
				echo "%0: error: something went wrong"
				exit -1
			fi
			plotdat anom 1981 2010 $series > aap.dat
			mv aap.dat $series
			if [ $? != 0 -o ! -s $series ]; then
				rm $series
				echo "%0: error: something went wrong"
				exit -1
			fi
		fi
		if [ -s nonmissing_erai_${var}.nc ]; then
		if [ \( ! -s nonmissing_erai_${var}_$area.dat \) -o nonmissing_erai_${var}_$area.dat -ot nonmissing_erai_${var}.nc ]; then
			get_index nonmissing_erai_${var}.nc 0 360 $lats lsmask lsmask07.nc $landsea standardunits > nonmissing_$series
			if [ $? != 0 -o ! -s nonmissing_$series ]; then
				rm nonmissing_$series
				echo "%0: error: something went wrong"
				exit -1
			fi
			plotdat anom 1981 2010 nonmissing_$series > aap.dat
			mv aap.dat nonmissing_$series
		fi
		fi
	done
done
