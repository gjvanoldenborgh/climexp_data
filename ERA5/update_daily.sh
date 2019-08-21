#!/bin/bash
###set -x
# this assumes Philippe downloads the updates.
yrnow=`date +%Y -d "2 months ago"`
cdo="cdo -r -f nc4 -z zip"
sourcedir=/net/pc170547/nobackup_2/users/sager/ERA5
vars=`ls $sourcedir/2010/day/era5_201001* | sed -e "s@$sourcedir/2010/day/era5_201001_@@" -e 's/\..*$//'`
echo "DEBUG: only take the non-flux parametres, the others are wrong 21-aug-2019"
vars="t2m msl z500 q500 sfcWind sfcWindmax sp" # these are OK 21-aug-2019
filelist=""
for var in $vars; do
    if [ $var != 3d ]; then
        yr=1978
        sourcefiles=""
        while [ $yr -lt $yrnow ]; do
            ((yr++))
            yearfiles="$sourcedir/$yr/day/era5_${yr}??_${var}.nc"
            firstfile=`ls $yearfiles | head -n 1`
            if [ -n "$firstfile" -a -s "$firstfile" ]; then
                sourcefiles="$sourcefiles $yearfiles"
            fi
            ###echo sourcefiles=$sourcefiles
        done

#       global 0.5 degree version, regional 0.25 degree versions

        regions="05 eu"
        for region in $regions; do
            case $region in
                05) lon1=;lon2=;lat1=;lat2=;;
                eu) lon1=-30;lon2=40;lat1=30;lat2=75;;
                *) echo "unknown region $region"; exit -1;;
            esac
            mkdir -p $region/$var
            files_region=""
            for file in $sourcefiles; do
                file_region=$region/$var/`basename $file`
                if [ ! -s $file_region -o $file_region -ot $file ]; then
                    if [ $region = 05 ]; then
                        echo "averagefieldspace $file 2 2 $file_region"
                        averagefieldspace $file 2 2 $file_region
                    else
                        echo "$cdo sellonlatbox,$lon1,$lon2,$lat1,$lat2 $file $file_region"
                        $cdo sellonlatbox,$lon1,$lon2,$lat1,$lat2 $file $file_region
                    fi
                fi
                files_region="$files_region $file_region"
            done
            lastfile=`ls -t $files_region | head -n 1`
            if [ $region = 05 ]; then
                file=era5_${var}_daily.nc
            else
                file=era5_${var}_daily_$region.nc
            fi
            if [ $lastfile -nt $file -o "$1" = force ]; then
                echo $$cdo copy $files_region $file
                $cdo copy $files_region $file
                ncatted -a title,global,c,c,"ERA5 reanalysis, https://www.ecmwf.int/en/forecasts/datasets/reanalysis-datasets/era5" $file
                . $HOME/climexp/add_climexp_url_field.cgi
                filelist="$filelist $file"
                if [ $var = sfcWind -o $var = sfcWindmax ]; then
                    ncatted -a units,$var,a,c,"m/s" $file
                fi
                $HOME/NINO/copyfiles.sh $file
            fi
        done
    fi
done
