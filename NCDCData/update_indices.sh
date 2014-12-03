#!/bin/sh
# http://www.ncdc.noaa.gov/cag/time-series/global/globe/land_ocean/p12/12/1880-2014.csv
# http://www.ncdc.noaa.gov/cag/time-series/global/globe/land/p12/12/1880-2014.csv
# http://www.ncdc.noaa.gov/cag/time-series/global/globe/ocean/p12/12/1880-2014.csv
base=http://www.ncdc.noaa.gov/cag/time-series/global
yrnow=`date -d "1 month ago" "+%Y"`

files=""
for region in gl # nh sh are not available any more
do
    case $region in
        gl) dir=globe;regionname=global;;
        nh) regionname="Northern Hemisphere";;
        sh) regionname="Southern Hemisphere";;
    esac
    for area in land ocean land_ocean
    do
        file=1880-$yrnow.csv
        [ -f $file ] && rm $file # they all have the same name...
        echo wget $base/$dir/$area/p12/12/$file
        wget $base/$dir/$area/p12/12/$file
        if [ $area = land_ocean ]; then
            myfile=ncdc_${region}.dat
        else
            myfile=ncdc_${region}_${area}.dat
        fi
        cat > $myfile <<EOF
# $regionname $area mean temperature anomalies from <a href="http://www.ncdc.noaa.gov/monitoring-references/faq/anomalies.php">NCDC</a>
# Ta [K] surface temperature anomaly
EOF
        egrep '^[12]' $file | tr ',' ' ' >> $myfile
        yrfile=`basename $myfile .dat`_yr.dat
        daily2longer $myfile 1 mean > $yrfile
        files="$files $myfile $yrfile"
        plotdat $yrfile > `basename $yrfile .dat`.txt
    done
done
$HOME/NINO/copyfilesall.sh $files

