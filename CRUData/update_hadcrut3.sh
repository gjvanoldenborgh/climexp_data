#!/bin/sh
echo "Get HadCRUT3.nc, CRUTEM3.nc, hadsst2, crutem3_hadsst2 from UKMO/CRU by hand"

for file in HadCRUT3.nc CRUTEM3.nc hadsst2.ctl crutem3_hadsst2.ctl
do
    case $file in
	HadCRUT3.nc|CRUTEM3.nc) var=temp;outfile=nonmissing_$file;;
	hadsst2.ctl) var=SSTa;outfile=nonmissing_`basename $file .ctl`.nc;;
	crutem3_hadsst2.ctl) var=T;outfile=nonmissing_`basename $file .ctl`.nc;;
	*) echo error: unknown file $file; exit -1;;
    esac
    if [ \( ! -s $outfile \) -o $outfile -ot $file ]; then
	if [ ${file%ctl} != $file ]; then
	    ctlfile=$file
	    open=open
	else
	    ctlfile=`basename $file .nc`.ctl
	    open=xdfopen
	    cat > $ctlfile <<EOF
DSET ^$file
zdef unspecified
EOF
	fi
	grads -b -l <<EOF
$open $ctlfile
set t 1 last
set x 1 72
define nonmissing = const(const(${var},1),0,-u)
set sdfwrite $outfile
sdfwrite nonmissing
clear sdfwrite
quit
EOF
	cdo -b 32 -r settaxis,1850-01-01,0:00,1mon $outfile aap.nc
	mv aap.nc $outfile
    fi
done

for var in t2m sst t2msst
do
    case $var in
	t2msst) file=HadCRUT3.nc
	    lsmask=ls_hadsst2.nc
	    areas="gl nh sh arctic antarctic";;
	t2m) file=CRUTEM3.nc
	    lsmask=ls_crutem3.nc
	    areas="gl nh sh land landnoice arctic antarctic";;
	sst) file=hadsst2.ctl
	    lsmask=ls_hadsst2.nc
	    areas="gl nh sh sea seanoice seaice_n seaice_s";;
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
	series=hadcrut3_${var}_$area.dat
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
