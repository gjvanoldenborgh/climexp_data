#!/bin/sh
base=ftp://ftp.aviso.oceanobs.com/pub/oceano/AVISO/indicators/msl/

file=MSL_Serie_MERGED_Global_IB_RWT_GIA_Adjust.nc
cp $file $file.old
wget -N $base/$file
cmp $file $file.old
if [ $? != 0 ]; then
    # yes it is netcdf, no it is not CF_compilant...
    ncrename -O -v PARAM,msl -v JOUR,time -d A,time $file aap.nc
    ncks -O -v msl aap.nc noot.nc
    ncdump noot.nc > noot.cdl
    sed -e '/time:units/d' -e 's/time:long_name/time:units/' noot.cdl > mies.cdl
    ncgen -o mies.nc mies.cdl
    echo "Not yet ready!!!'
exit -1
    ./tenday2dat mies.nc > msl_adjusted.dat
    $HOME/NINO/copyfiles.sh msl_adjusted.dat
fi
