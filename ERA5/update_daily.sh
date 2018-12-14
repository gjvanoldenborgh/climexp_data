#!/bin/bash
# this assumes Philippe downloads the updates.
cdo="cdo -r -f nc4 -z zip"
sourcedir=/net/pc170547/nobackup_2/users/sager/ERA5
vars=`ls $sourcedir/2010/day/era5_201001* | sed -e "s@$sourcedir/2010/day/era5_201001_@@" -e 's/\..*$//'`
filelist=""
for var in $vars; do
    if [ $var != 3d ]; then
        sourcefiles="$sourcedir/????/day/era5_??????_${var}.nc"
        lastfile=`ls -t $sourcefiles | head -n 1`
        file=era5_${var}_daily.nc
        if [ $lastfile -nt $file ]; then
            echo $var
            $cdo copy $sourcefiles $file
            filelist="$filelist $file"
        fi
        ncatted -a title,global,c,c,"ERA5 reanalysis, https://www.ecmwf.int/en/forecasts/datasets/reanalysis-datasets/era5" $file
        . $HOME/climexp/add_climexp_url_field.cgi
    fi
done
ncatted -a units,sfcWind,a,c,"m/s" era5_sfcWind_daily.nc
ncatted -a units,sfcWindmax,a,c,"m/s" era5_sfcWindmax_daily.nc
if [ -n "$filelist" ]; then
    rsync -v $filelist bhlclim:climexp/ERA5/
fi
