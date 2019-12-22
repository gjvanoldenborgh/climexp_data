#!/bin/sh

# gridded temperature fields

version=latest
base=ftp://ftp.bom.gov.au/anon/home/ncc/www/change/
url=http://www.bom.gov.au/climate/data/acorn-sat/
gfortran -o gentime gentime.f90
for var in tmin tmax tave; do
    file=${var}_month_$version.nc
    if [ ! -s $file ]; then
        wget --no-check-certificate $base/acorn_sat/$file
    fi
    newfile=${file%.nc}_ce.nc
    cdlfile=${file%.nc}.cdl
    year=`ncdump $file | head -100 | fgrep 'year = ' | head -1 | awk '{ print $3 }'`
    ((ntime=12*year))
    ./gentime $ntime > timedef.txt
    ncdump $file | sed -e '/month = /d' -e '/short month/d' \
        -e "s/year = $year/time = $ntime/" \
        -e "s/short year(year)/float time(time)/" \
        -e "s/year:valid_min = 1910/time:units = \"months since 1910-01-01\"/" \
        -e 's/year, month/time/' \
        -e '/year = /,/;/d' \
        -e "/data:/r timedef.txt" \
        > $cdlfile
    ncgen -o $newfile $cdlfile
    export file=$newfile
    case $var in
        tmin) long_name="Daily Minimum Near-Surface Air Temperature";standard_name="air_temperature";;
        tmax) long_name="Daily Maximum Near-Surface Air Temperature";standard_name="air_temperature";;
        tave) long_name="Near-Surface Air Temperature";standard_name="air_temperature";;
    esac
    ncatted -a units,longitude,m,c,"degrees_east" -a units,latitude,m,c,"degrees_north" \
            -a units,$var,a,c,'Celsius' \
            -a long_name,$var,a,c,"$long_name" -a standard_name,$var,a,c,"$standard_name" \
        $file
    . $HOME/climexp/add_climexp_url_field.cgi
    rm $cdlfile
    $HOME/NINO/copyfiles.sh $file

    if [ -n "$download_HQdailyT_stations" ]; then    
        v=$var
        [ $v = tave ] && v=tmean
        file=HQ_daily_${v}_txt.tar
        if [ ! -s $file ]; then
            wget --no-check-certificate $base/HQdailyT/$file
        fi
    fi
    
    if [ -n "$download_acorn_sat_daily_stations" ]; then
        version=v2
        file=acorn_sat_${version}_daily_$var.tar.gz
        wget --no-check-certificate $base/ACORN_SAT_daily/$file
    fi
done
