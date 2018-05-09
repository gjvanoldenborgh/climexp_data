#!/bin/sh
#
# generate historical potential evaporation files
#
###set -x
files=""
mofiles=""
vars="rsns rlns tmin tmax wspd tdew t2m sp"
yr=1979
while [ -s t2m$yr.nc ]; do
    if [ ! -s evappot$yr.nc ]; then
        for var in $vars; do
            if [ ! -s $var$yr.nc ]; then
                echo "$0: error: cannot locate $var$yr.nc"
                exit -1
            fi
        done
        set -x
        ./compute_Epot_ERA.py $yr
        if [ $yr = 1980 -o $yr = 2013 ]; then # no idea why these go wrong...
            ncrename -d axis_0,time -v axis_0,time evappot$yr.nc aap.nc
            cdo -r settaxis,1980-01-01,12:00,1day aap.nc evappot$yr.nc
        fi
        cdo monmean evappot$yr.nc evappot${yr}_mo.nc
        set +x
    fi
    files="$files evappot$yr.nc"
    mofiles="$mofiles evappot${yr}_mo.nc"
    ((yr++))
done
mo=1
while [ -s t2m$yr$mo ]; do
    if [ ! -s evappot$yr$mo.nc ]; then
        for var in $vars; do
            if [ ! -s $var$yr$mo.nc ]; then
                echo "$0: error: cannot locate $var$yr$mo.nc"
                exit -1
            fi
        done
        set -x
        ./compute_Epot_ERA.py $yr$mo
        cdo monmean evappot$yr$mo.nc evappot${yr}${mo}_mo.nc
        set +x
    fi
    files="$files evappot$yr$mo.nc"
    mofiles="$mofiles evappot${yr}${mo}_mo.nc"
    ((mo++))
done
set -x
cdo -r -f nc4 -z zip copy $mofiles erai_evappot.nc
rsync erai_evappot.nc bhlclim:climexp/ERA-interim/
cdo -r -f nc4 -z zip copy $files erai_evappot_daily.nc
rsync erai_evappot_daily.nc bhlclim:climexp/ERA-interim/
set +x
