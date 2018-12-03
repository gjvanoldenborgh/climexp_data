#!/bin/sh
# download GPCC v8
download=true
base=ftp://ftp.dwd.de/pub/data/gpcc/full_data_2018/
for res in 25 10 05 025
do
    file=full_data_monthly_v2018_$res.nc
    if [ $download = true ]; then
        wget -N $base/$file.gz
        gunzip -c $file.gz > $file
    fi
    ncatted -a units,lat,m,c,"degrees_north" $file
    cdo -r -f nc4 -z zip selvar,precip $file gpcc_V8_${res}.nc
    cdo -r -f nc4 -z zip selvar,numgauge $file gpcc_V8_${res}_n.nc
    cdo -r -f nc4 -z zip ifthen gpcc_V8_${res}_n.nc gpcc_V8_${res}.nc gpcc_V8_${res}_n1.nc
    for file in gpcc_V8_${res}_n.nc gpcc_V8_${res}.nc gpcc_V8_${res}_n1.nc; do
        . $HOME/climexp/add_climexp_url_field.cgi
    done
    $HOME/NINO/copyfiles.sh gpcc_V8_${res}_n.nc gpcc_V8_${res}.nc gpcc_V8_${res}_n1.nc
done
