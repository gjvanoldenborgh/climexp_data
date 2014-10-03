#!/bin/sh

for file in ghcn_cams_10.ctl
do
    case $file in
	ghcn_cams_10.ctl) var=tmp2m;outfile=nonmissing_`basename $file .ctl`.nc;;
	*) echo error: unknown file $file; exit -1;;
    esac
if [ \( ! -s $outfile \) -o $outfile -ot $file ]; then
	grads -b -l <<EOF
open $file
set t 1 last
set x 1 360
define nonmissing = const(const(${var},1),0,-u)
set sdfwrite $outfile
sdfwrite nonmissing
clear sdfwrite
quit
EOF
	cdo -r settaxis,1948-01-01,0:00,1mon $outfile aap.nc
	mv aap.nc $outfile
    fi
done

for var in t2m
do
    case $var in
	t2m) file=ghcn_cams_10.ctl
	    lsmask=ls_ghcn_cams_10.nc
	    areas="land landnoice arctic antarctic";;
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
	    land*) landsea=land;;
	    sea*) landsea=sea;;
	    *) landsea=all
	esac
	series=ghcncams_${var}_$area.dat
	if [ \( ! -s $series \) -o $series -ot $file ]; then
	    echo "Generating $series"
	    get_index $file 0 360 $lats standardunits lsmask $lsmask $landsea > $series
	fi
	nonmissingseries=nonmissing_$series
	nonmissingfile=nonmissing_$file
	if [ ${nonmissingfile%ctl} != $nonmissingfile ]; then
	    nonmissingfile=${nonmissingfile%ctl}nc
	fi
	if [ \( ! -s $nonmissingseries \) -o $nonmissingseries -ot $nonmissingfile ]; then
	    echo "Generating $nonmissingseries"
	    get_index $nonmissingfile 0 360 $lats lsmask $lsmask $landsea > $nonmissingseries
	fi
    done
done
