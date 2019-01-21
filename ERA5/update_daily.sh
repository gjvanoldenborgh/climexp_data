#!/bin/bash
# this assumes Philippe downloads the updates.
yrnow=`date +%Y -d "2 months ago"`
cdo="cdo -r -f nc4 -z zip"
sourcedir=/net/pc170547/nobackup_2/users/sager/ERA5
vars=`ls $sourcedir/2010/day/era5_201001* | sed -e "s@$sourcedir/2010/day/era5_201001_@@" -e 's/\..*$//'`
filelist=""
for var in $vars; do
    if [ $var != 3d ]; then
        yr=1978
        sourcefiles=""
        while [ $yr -lt $yrnow ]; do
            ((yr++))
            yearfiles="$sourcedir/$yr/day/era5_${yr}??_${var}.nc"
            c=`echo $yearfiles | wc -w`
            if [ $c = 12 -o $yr = $yrnow ]; then
                sourcefiles="$sourcefiles $yearfiles"
            else
                sourcefiles=""
            fi
            ###echo sourcefiles=$sourcefiles
        done
        lastfile=`ls -t $sourcefiles | head -n 1`
        file=era5_${var}_daily.nc
        if [ $lastfile -nt $file -o "$1" = force ]; then
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
    rsync -v $filelist climexp.climexp-knmi.surf-hosted.nl:climexp/ERA5/
fi
