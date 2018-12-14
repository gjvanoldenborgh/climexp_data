#!/bin/bash
# See mail form Bert Wouters
#   land
base=ftp://podaac.jpl.nasa.gov/allData/tellus/L3/land_mass/RL05/netcdf/
file=\*CSR\*LND\*.nc
wget -q -N "$base/$file"
thisfile=`ls -t $file | head -1`
if [ -s "$thisfile" ]; then
	landfile=$thisfile
fi

#   ocean
base=ftp://podaac.jpl.nasa.gov/allData/tellus/L3/ocean_mass/RL05/netcdf/
file=\*CSR\*OCN\*.nc
wget -q -N "$base/$file"
thisfile=`ls -t $file | head -1`
if [ -s "$thisfile" ]; then
    oceanfile=$thisfile
fi

# this gets rid of the irregular time axis - missing months are set to undefined 
# and non-centered months are assumed centered.
cdo inttime,2003-01-17,0:00,1day $landfile grace_land_daily.nc
daily2longerfield grace_land_daily.nc 12 mean minfac 0.25 grace_land.nc
file=grace_land.nc
. $HOME/climexp/add_climexp_url_field.cgi
$HOME/NINO/copyfiles.sh grace_land.nc
rm grace_land_daily.nc

cdo inttime,2003-01-17,0:00,1day $oceanfile grace_ocean_daily.nc
daily2longerfield grace_ocean_daily.nc 12 mean minfac 0.25 grace_ocean.nc
file=grace_ocean.nc
. $HOME/climexp/add_climexp_url_field.cgi
$HOME/NINO/copyfiles.sh grace_ocean.nc
rm grace_ocean_daily.nc

$HOME/NINO/copyfiles.sh grace_land.nc grace_ocean.nc
