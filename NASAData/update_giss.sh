#!/bin/sh

for file in giss_temp_both_1200.nc giss_temp_land_1200.nc giss_temp_sea_1200.nc
do
    var=tempanomaly
    outfile=nonmissing_$file
    if [ \( ! -s $outfile \) -o $outfile -ot $file ]; then
	grads -b -l <<EOF
sdfopen $file
set t 1 last
set x 1 360
define nonmissing = const(const(${var},1),0,-u)
set sdfwrite $outfile
sdfwrite nonmissing
clear sdfwrite
quit
EOF
	cdo -b 32 -r settaxis,1880-01-01,0:00,1mon $outfile aap.nc
	mv aap.nc $outfile
    fi
done
for var in t2m sst t2msst
do
    case $var in
	t2msst) file=giss_temp_both_1200.nc
	    areas="gl nh sh land sea landnoice seanoice arctic antarctic";;
	t2m) file=giss_temp_land_1200.nc
	    areas="gl nh sh land sea landnoice seanoice arctic antarctic";;
	sst) file=giss_temp_sea_1200.nc
	    areas="gl nh sh sea seanoice seaice_n seaice_s";;
	*) echo error udgfewjh; exit -1;;
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
	    land*) landsea=land;;
	    sea*) landsea=sea;;
	    *) landsea=all
	esac
	series=giss_${var}_$area.dat
	if [ $var = t2m -a \( $area = gl -o $area = sh -o $area = nh \) ]; then
	    cp giss_ts_${area}_m.dat $series
	elif [ $var = t2msst -a \( $area = gl -o $area = sh -o $area = nh \) ]; then
	    cp giss_al_${area}_m.dat $series
	elif [ \( ! -s $series \) -o $series -ot $file ]; then
	    echo "Generating $series"
	    get_index $file 0 360 $lats lsmask lsmask.nc $landsea standardunits > $series
	fi
	nonmissingseries=nonmissing_$series
	nonmissingfile=nonmissing_$file
	if [ ${nonmissingfile%ctl} != $nonmissingfile ]; then
	    nonmissingfile=${nonmissingfile%ctl}nc
	fi
	if [ \( ! -s $nonmissingseries \) -o $nonmissingseries -ot $nonmissingfile ]; then
	    echo "Generating $nonmissingseries"
	    get_index $nonmissingfile 0 360 $lats lsmask lsmask.nc $landsea > $nonmissingseries
	fi
    done
done
