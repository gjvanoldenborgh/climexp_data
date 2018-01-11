#!/bin/sh
cdo="cdo -r -R -b 32 -f nc4 -z zip"
yr=1979
mo=1
mm=`printf %02i $mo`
files=""
while [ -s u10$yr.grib -o -s u10$yr$mm.grib ]; do
    if [ -s u10$yr.grib ]; then
        ufile=u10$yr.grib
        vfile=v10$yr.grib
        ((yr++))
    elif [ -s u10$yr$mm.grib ]; then
        ufile=u10$yr$mm.grib
        vfile=v10$yr$mm.grib
        ((mo++))
        if [ $mo -gt 12 ]; then
            ((mo=mo-12))
            ((yr++))
        fi
        mm=`printf %02i $mo`
    else
        echo "$0: error vgfcdsfwsq"; exit -1
    fi
    if [ ! -s $vfile ]; then
        echo "$0: error: cannot find $vfile"
        exit -1
    fi
    ext=${ufile#u10}
    ext=${ext%.grib}
    outfile=wspd$ext.nc
    if [ ! -s $outfile ]; then
        $cdo -shifttime,1hour -sqr $ufile /tmp/utmp$ext.nc
        $cdo -shifttime,1hour -sqr $vfile /tmp/vtmp$ext.nc
        $cdo add /tmp/utmp$ext.nc /tmp/vtmp$ext.nc ./wspd2tmp$ext.nc
        rm /tmp/utmp$ext.nc /tmp/vtmp$ext.nc
        $cdo -sqrt -daymean ./wspd2tmp$ext.nc $outfile
        ncrename -v var165,wspd $outfile
        ncatted -a units,wspd,a,c,"m/s" -a long_name,wspd,a,c,"10m wind speed sqrt(u10^2+v10^2) 3hr" $outfile
        rm ./wspd2tmp$ext.nc
    fi
    files="$files $outfile"
done
$cdo copy $files erai_wspd_daily.nc