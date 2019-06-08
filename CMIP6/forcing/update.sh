#!/bin/sh
base=http://solarisheppa.geomar.de/solarisheppa/sites/default/files/data/cmip6
file=solarforcing-ref-mon_input4MIPs_solar_CMIP_SOLARIS-HEPPA-3-2_gn_18500101-22991231.nc
wget -N $base/$file.gz
gunzip -c $file.gz > $file
for var in tsi f107 ap kp; do
    ncks -O -v $var $file cmip6_$var.nc
    netcdf2dat cmip6_$var.nc > cmip6_$var.dat
    touch cmip6_$var.nc
done
