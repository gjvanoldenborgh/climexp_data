#!/bin/sh
set -x
yrnow=`date +%Y`
yr=1895 # 2014
vars="ppt tmax tmin" # tdmean vpdmin vpdmax tmean vpr 
doit=false
while [ $yr -le $yrnow ]; do
    for var in $vars; do
        varname=$var
        case $var in
            ppt) units="mm/month";varname="prcp";long_name="precipitation";;
            tmax) units="Celsius";long_name="monthly mean of daily maximum temperature";;
            tmin) units="Celsius";long_name="monthly mean of daily minimum temperature";;
            *) echo "$0: error: know nothing about $var yet"; exit -1;;
        esac
        if [ ! -s ${var}_prism_$yr.nc -o $yr = $yrnow -o $yr = $((yrnow-1)) ]; then
            wget -q -N ftp://prism.nacse.org/monthly/$var/$yr/PRISM_${var}_stable_4kmM?_${yr}_all_bil.zip
            file=`ls -t PRISM_${var}_stable_4kmM?_${yr}_all_bil.zip  2> /dev/null | head -1`
            if [ -f "$file" ]; then
                unzip -o $file
            else
                wget -q -N ftp://prism.nacse.org/monthly/$var/$yr/PRISM_${var}_stable_4kmM?_${yr}??_bil.zip
                for mon in 01 02 03 04 05 06 07 08 09 10 11 12; do
                    file=`ls -t PRISM_${var}_stable_4kmM?_${yr}${mon}_bil.zip  2> /dev/null | head -1`
                    if [ -s "$file" ]; then
                        unzip -o $file
                    fi
                done
            fi
            for mon in 01 02 03 04 05 06 07 08 09 10 11 12; do
                bilfile=`ls PRISM_${var}_stable_4kmM?_${yr}${mon}_bil.bil 2> /dev/null | head -1`
                if [ ! -s "$file" ]; then
                    if [ $yr != $yrnow ]; then
                        echo "$0: cannot find $file"
                        exit -1
                    fi
                else
                    gdal_translate -of NetCDF PRISM_${var}_stable_4kmM?_${yr}${mon}_bil.bil aap.nc
                    cdo -r -f nc4 -z zip -settaxis,${yr}-${mon}-15,0:00,1month aap.nc noot.nc
                    ncrename -O -v Band1,$varname noot.nc PRISM_${var}_${yr}${mon}.nc
                    ncatted -a units,prcp,a,c,"$units" \
                            -a long_name,prcp,a,c,"$long_name" \
                        -a title,global,a,c,"PRISM analysis" PRISM_${var}_${yr}${mon}.nc
                fi
            done
            [ -s ${var}_prism_${yr}.nc ] && mv ${var}_prism_${yr}.nc ${var}_prism_${yr}.nc.old
            cdo -r -f nc4 -z zip copy PRISM_${var}_${yr}??.nc ${var}_prism_${yr}.nc
            if [ -s ${var}_prism_${yr}.nc.old ]; then
                cmp ${var}_prism_${yr}.nc ${var}_prism_${yr}.nc.old
                [ $? != 0 ] && doit=true # unfortunately this also triggers on the date in the history attribute, any ideas?
            else
                [ -s ${var}_prism_${yr}.nc ] && doit=true
            fi
            rm -f PRISM_${var}_${yr}??.nc `ls PRISM_${var}_stable_4kmM?_${yr} | fgrep -v .zip` aap.nc noot.nc
        fi
        if [ ! -s ${var}_prism_${yr}_25.nc -o ${var}_prism_${yr}_25.nc -ot ${var}_prism_$yr.nc ]; then
            averagefieldspace ${var}_prism_$yr.nc 6 6 ${var}_prism_${yr}_25.nc
        fi
    done # vars
    yr=$((yr+1))
done # yr

if [ $doit = true -o ! -s ${var}_prism.nc -o ! -s ${var}_prism_25.nc ]; then
    for ext in "" _25; do
        for var in $vars; do
            cdo -r -f nc4 -z zip copy ${var}_prism_????$ext.nc ${var}_prism$ext.nc
            $HOME/NINO/copyfiles.sh ${var}_prism$ext.nc
        done
    done
fi