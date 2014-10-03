#!/bin/sh
echo "Get ersstv3b, temp_anom bij hand"

for file in ersstv3b.ctl temp_anom.ctl
do
    case $file in
	ersstv3b.ctl) var=SST;yrbeg=1854;nx=180;outfile=nonmissing_`basename $file .ctl`.nc;;
	temp_anom.ctl) var=temp;yrbeg=1880;nx=72;outfile=nonmissing_`basename $file .ctl`.nc;;
	*) echo error: unknown file $file; exit -1;;
    esac
    if [ \( ! -s $outfile \) -o $outfile -ot $file ]; then
	grads -b -l <<EOF
open $file
set t 1 last
set x 1 $nx
define nonmissing = const(const(${var},1),0,-u)
set sdfwrite $outfile
sdfwrite nonmissing
clear sdfwrite
quit
EOF
	
	cdo -b 32 -r settaxis,${yrbeg}-01-01,0:00,1mon $outfile aap.nc
	mv aap.nc $outfile
    fi
done

for var in t2m sst
do
    case $var in
	t2m) file=temp_anom.ctl
	    lsmask=ls_temp_anom.nc
	    areas="land landnoice arctic antarctic";;
	sst) file=ersstv3b.ctl
	    lsmask=ls_ersstv3b.nc
	    areas="sea seanoice seaice_n seaice_s";;
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
	series=ncdc_${var}_$area.dat
	if [ \( ! -s $series \) -o $series -ot $file ]; then
	    echo "Generating $series"
	    get_index $file 0 360 $lats lsmask $lsmask $landsea standardunits > $series
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
cp ncdc_gl_land_ocean.dat ncdc_t2msst_gl.dat
cp ncdc_gl_land.dat ncdc_t2msst_land.dat
cp ncdc_gl_ocean.dat ncdc_t2msst_sea.dat
cp ncdc_nh_land_ocean.dat ncdc_t2msst_nh.dat
cp ncdc_sh_land_ocean.dat ncdc_t2msst_sh.dat
