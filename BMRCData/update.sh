#!/bin/sh
yr=1960
mo=0
day0=`date +%d`
if [ $day0 -lt 4 ]; then
	offset=1
else
	offset=0
fi
mm1=`date -d "$((offset)) month ago" "+%m" | sed -e 's/^0//'`
year1=`date -d "$((offset)) month ago" "+%Y"`

file=dummy
root=http://opendap.bom.gov.au:8080/thredds/dodsC/poama/peodas
dir=reanalysis
maked20=false
d20files=""
makesst=false
sstfiles=""
while [ $mo = 0 -o -s $file ]
do
    mo=$((mo+1))
    if [ $mo -gt 12 ]; then
        mo=$((mo-12))
        yr=$((yr+1))
    fi
    if [ $mo -lt 10 ]; then
        mm=0$mo
    else
        mm=$mo
    fi
    file=d20_$yr$mm.nc
    if [ $dir != reanalysis ]; then
        file=rt_$file
    fi
    tmpfile=aap$$.nc
    if [ \( $yr != $year1 -o $mo != $mm1 \) -a ! -s $file ]; then
        echo "getting $file..."
        [ -f $tmpfile ] && rm $tmpfile
        ncks -v ISTHERM $root/$dir/mo_$yr$mm.nc $tmpfile
        if [ ! -s $tmpfile ]; then
            echo "switching to real-time data"
            dir=realtime_analysis/main
            file=rt_$file
            ncks -v ISTHERM $root/$dir/mo_$yr$mm.nc $tmpfile
            if [ ! -s $tmpfile ]; then
                echo "cannot find $file"
                exit
            fi
        fi
        cdo settaxis,${yr}-${mm}-15,0:00:00,1month $tmpfile $file
        maked20=true
    fi
    if [ -s $file ]; then
        d20files="$d20files $file"
    fi
    file=sst_$yr$mm.nc
    if [ $dir != reanalysis ]; then
        file=rt_$file
    fi
    if [ \( $yr != $year1 -o $mo != $mm1 \) -a ! -s $file ]; then
        echo "getting $file..."
        [ -f $tmpfile ] && rm $tmpfile
        ncks -v TEMP -d level,750. $root/$dir/mo_$yr$mm.nc $tmpfile
        cdo settaxis,${yr}-${mm}-15,0:00:00,1month $tmpfile $file
        makesst=true
    fi
    if [ -s $file ]; then
        sstfiles="$sstfiles $file"
    fi
done
if [ $maked20 = true -o ! -s d20.nc ]; then
    cdo -r -f nc4 -z zip copy $d20files d20.nc
    get_index d20.nc 120 280 -5 5 > wwv_poama.dat
    $HOME/NINO/copyfiles.sh d20.nc wwv_poama.dat
fi
if [ $makesst = true -o ! -s sst.nc ]; then
    cdo -r -f nc4 -z zip copy $sstfiles sst.nc
    get_index sst.nc 190 240 -5 5 > nino34_poama.dat
    $HOME/NINO/copyfiles.sh sst.nc nino34_poama.dat
fi
