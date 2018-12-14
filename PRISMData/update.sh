#!/bin/bash
yr=`date +%Y`
mo=`date +%m`
if [ "$1" != force -a -f downloaded_$yr$mo ]; then
  echo "Already downloaded PRISM this month"
  exit
fi

vars="ppt tmax tmin tmean tdmean vpdmax" #  vpdmin vpr 
for var in $vars; do
    yrnow=`date +%Y`
    yr=1895 # 2014
    doit=false
    files=""
    files25=""
    while [ $yr -le $yrnow ]; do
        varname=$var
        case $var in
            ppt) units="mm/month";varname="prcp";long_name="precipitation";;
            tmax) units="Celsius";long_name="monthly mean of daily maximum temperature";;
            tmin) units="Celsius";long_name="monthly mean of daily minimum temperature";;
            tmean) units="Celsius";long_name="monthly mean temperature";;
            tdmean) units="Celsius";long_name="monthly mean of dew point temperature";;
            vpdmax) units="hPa";long_name="monthly mean of daily maximum vapor pressure deficit";;
            *) echo "$0: error: know nothing about $var yet"; exit -1;;
        esac
        if [ ! -s ${var}_prismM?_$yr.nc -o $yr = $yrnow -o $yr = $((yrnow-1)) ]; then
            wget -q -N ftp://prism.nacse.org/monthly/$var/$yr/PRISM_${var}_stable_4kmM?_${yr}_all_bil.zip
            file=`ls -t PRISM_${var}_stable_4kmM?_${yr}_all_bil.zip  2> /dev/null | head -1`
            if [ -f "$file" ]; then
                unzip -qq -o $file
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
                version=${bilfile##*_4km}
                version=${version%%_*}
                if [ ! -s "$bilfile" ]; then
                    if [ $yr != $yrnow ]; then
                        echo "$0: warning: cannot find bilfile for yr,mon = ",$yr,$mon
                    fi
                else
                    gdal_translate -of NetCDF $bilfile aap.nc
                    cdo -r -f nc4 -z zip -settaxis,${yr}-${mon}-15,0:00,1month aap.nc noot.nc
                    ncrename -O -v Band1,$varname noot.nc PRISM_${var}_${yr}${mon}.nc
                    ncatted -a units,$varname,a,c,"$units" \
                            -a long_name,$varname,m,c,"$long_name" \
                            -a title,global,a,c,"PRISM analysis 4k$version" PRISM_${var}_${yr}${mon}.nc
                fi
            done
            f=`ls -t ${var}_prismM?_${yr}.nc | head -1`
            [ -s "$file" ] && mv $file $file.old
            cdo -r -f nc4 -z zip copy PRISM_${var}_${yr}??.nc ${var}_prism${version}_${yr}.nc
            if [ -s ${var}_prism${version}_${yr}.nc.old ]; then
                cmp ${var}_prism${version}_${yr}.nc ${var}_prism${version}_${yr}.nc.old
                [ $? != 0 ] && doit=true # unfortunately this also triggers on the date in the history attribute, any ideas?
            else
                [ -s ${var}_prism${version}_${yr}.nc ] && doit=true
            fi
            rm -f PRISM_${var}_${yr}??.nc `ls PRISM_${var}_stable_4kmM?_${yr}* | fgrep -v .zip` aap.nc noot.nc ${var}_prismM?_????.old
        fi
        f=`ls -t ${var}_prismM?_${yr}.nc | head -1`
        f25=${f%.nc}_25.nc
        if [ -s "$f" ]; then
            if [ ! -s "$f25" -o "$f25" -ot "$f" ]; then
                averagefieldspace $f 6 6 $f25
            fi
            files="$files $f"
            files25="$files25 $f25"
        fi
        yr=$((yr+1))
    done # yr

    if [ $doit = true -o ! -s ${var}_prism${version}.nc -o ! -s ${var}_prism${version}_25.nc ]; then
        cdo -r -f nc4 -z zip copy $files ${var}_prism${version}.nc
        cdo -r -f nc4 -z zip copy $files25 ${var}_prism${version}_25.nc
        for file in ${var}_prism${version}.nc $files25 ${var}_prism${version}_25.nc; do
            ncatted -h -a institution,global,c,c,"PRISM climate group, Northwest Alliance for Computational Science & Engineering (NACSE), based at Oregon State University" \
                    -a source_url,global,c,c,"http://prism.oregonstate.edu" \
                    -a contact,global,c,c,"prism-questions@nacse.org" $file
            . $HOME/climexp/add_climexp_url_field.cgi
        done
        ###$HOME/NINO/copyfiles.sh ${var}_prism${version}_25.nc ${var}_prism${version}.nc
        rsync ${var}_prism${version}_25.nc ${var}_prism${version}.nc bhlclim:climexp/PRISMData/
    fi

done # vars

yr=`date +%Y`
mo=`date +%m`
date > downloaded_$yr$mo
