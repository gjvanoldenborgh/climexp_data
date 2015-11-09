#!/bin/sh
# fix paleo-netcdf...

ncatted -O -a units,pdsi,m,c,"1" \
    -a units,lon,m,c,"degrees_east" -a standard_name,lon,a,c,"longitude" \
    -a longname,lon,d,c,"" -a long_name,lon,a,c,"longitude" -a axis,lon,a,c,"X" \
    -a units,lat,m,c,"degrees_north" -a standard_name,lat,a,c,"latitude" \
    -a longname,lat,d,c,"" -a long_name,lat,a,c,"latitude" -a axis,lat,a,c,"Y" \
    -a units,time,a,c,"years since 0-01-01 00:00:00" \
    -a calendar,time,a,c,"standard" \
    -a title,global,a,c,"0-2012 Old World Drought Atlas (OWDA, Cook et al., 2015) (summers only)" \
    owda_hd_fix1_500.nc aap.nc
ncpdq -O -a time,lat,lon aap.nc noot.nc
cdo -r -f nc4 -z zip copy noot.nc owda_hd_fix1_500_fixed.nc