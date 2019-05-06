#!/bin/bash
# because I still have not learned enough python
yrnow=`date +%Y`
monow=`date +%m`
if [ -s downloaded_$yrnow$monow ]; then
    echo "$0: already downloaded Copernicus data this month"
    exit
fi
cdo="cdo -f nc4 -z zip"
ncks="ncks -4 -L 5 -O"
# get new data from CDS
if [ "$1" != nodownload ]; then
    echo "Getting data from CDS..."
    latestfile=`ls -t *.zip | head -1`
    rm $latestfile # it usually is incomplete
    ./update_sealevel.py
fi
yr=1992
while [ $yr -lt $yrnow ]; do
    ((yr++))
    mkdir -p $yr
    for var in sla adt ugos vgos; do
        mkdir -p $yr/$var
    done
    cd $yr
    zipfiles=../satellite-sea-level-global_${yr}*.zip
    for zipfile in $zipfiles; do
        if [ -s $zipfile  ]; then
            echo "unzipping and processing $zipfile"
            unzip -o -u $zipfile
        fi
    done
    for file in *.nc; do
        if [ -s $file ]; then
            c=`file $file | fgrep -c NetCDF`
            if [ $c = 1 ]; then
                echo compressing $file
                $ncks $file /tmp/$file
                mv /tmp/$file $file
            fi
            for var in sla adt ugos vgos; do
                varfile=$var/${var}_${file}
                if [ ! -s $varfile ]; then
                    $ncks -v $var $file $var/${var}_${file}
                fi
            done
            fi
    done
    cd ..
done

for var in sla adt ugos vgos; do
    echo "Var $var ..."
    file=copernicus_${var}_daily.nc
    $cdo copy ????/$var/*.nc $file
    ncatted -h -a time_coverage_start,global,d,, \
        -a time_coverage_end,global,d,, \
        -a time_coverage_duration,global,d,, $file
    . ~/climexp/add_climexp_url_field.cgi
    monfile=${file%_daily.nc}.nc
    daily2longerfield $file 12 mean $monfile
    file=$monfile
    ncatted -a -h time_coverage_resolution,global,d,, $file
    . ~/climexp/add_climexp_url_field.cgi
    series=global_${file%.nc}.dat
    get_index $file 0 360 -90 90 > $series
    $HOME/NINO/copyfiles.sh $file
    $HOME/NINO/copyfilesall.sh $series
done
date > downloaded_$yrnow$monow
