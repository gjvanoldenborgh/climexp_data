#!/bin/sh
if [ -x /usr/bin/ncdump-hdf ]; then
    hdf_ncdump=ncdump-hdf
else
    hdf_ncdump=ncdump
fi
yr=1978
mo=11
list=""
file=o3col${yr}${mo}aver.hdf
doit=false
while [ -s $file ]
do
    ncfile=`basename $file .hdf`.nc
    list="$list $ncfile"
    if [ ! -s $ncfile ]; then
        echo "converting $file"
        nt=$((12*(yr-1978) + (mo-1)))
        cp vars.txt aap.txt
        echo " time = $nt ;" >> aap.txt
        $hdf_ncdump $file > aap.cdl
        sed -e 's/fakeDim0/latitude/' -e s'/fakeDim1/longitude/' -e 's/fakeDim2 = 181/time = 1/' \
            -e '/variables:/r defvars.txt' \
            -e 's/Average_O3_column(latitude, longitude)/Average_O3_column(time, latitude, longitude)/' \
            -e '/short Average_O3_column/r defcol.txt' \
            -e 's/Average_O3_std(fakeDim2, fakeDim3)/Average_O3_std(time, latitude, longitude)/' \
            -e '/short Average_O3_std/r defstd.txt' \
            -e '/data:/r aap.txt' \
            aap.cdl > noot.cdl
        ncgen -o $ncfile noot.cdl
        rm aap* noot*
        doit=true
    fi
    mo=$((mo+1))
    if [ $mo -gt 12 ]; then
        mo=1
        yr=$((yr+1))
    fi
    if [ $mo -lt 10 ]; then
	    file=o3col${yr}0${mo}aver.hdf
    else
	    file=o3col${yr}${mo}aver.hdf
    fi
done
echo $file did not exist
if [ $doit = true ]; then
    cdo copy $list o3col.nc 2>&1 | fgrep -v Gregorian
    ncks -O -v Average_O3_column o3col.nc o3col1.nc
    $HOME/NINO/copyfiles.sh o3col1.nc
fi
