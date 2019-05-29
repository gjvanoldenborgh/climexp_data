#!/bin/bash
cdo="cdo -r -b 32 -f nc4 -z zip"

# first the daily sums, we take the 0-24 UTC sum.

yr=2008
lastok=true
make km2latlon
date > log
while [ $lastok = true ]; do
    yr=$((yr+1))

    zipfile=RAD_NL25_RAC_MFBS_24H_${yr}_NETCDF.zip
    wget -N http://opendap.knmi.nl/knmi/thredds/fileServer/radarprecipclim/RAD_NL25_RAC_MFBS_24H_NC/$zipfile
    if [ ! -s $zipfile ]; then
        lastok=false
    else
        sumfile=radar_sum_$yr.nc
        if [ -s $zipfile -a ! -s $sumfile -o $sumfile -ot $zipfile ]; then
            echo "unzipping $zipfile"
            unzip -q -o $zipfile
            month=0
            while [ $month -lt 12 ]; do
                month=$((month+1))
                mm=`printf %02i $month`
                day=0
                case $month in
                    1|3|5|7|8|10|12) dpm=31;;
                    2) dpm=28;;
                    4|6|9|11) dpm=30;;
                    *) echo "what?";exit -1;;
                esac
                if [ $dpm = 28 -a $((yr%4)) = 0 ]; then
                    dpm=29
                fi
                list=""
                while [ $day -lt $dpm ]; do
                    day=$((day+1))
                    dd=`printf %02i $day`
                    ###echo "Processing $yr$mm$dd"
                    daysumfile=$yr/$mm/RAD_NL25_RAC_MFBS_24H_$yr$mm${dd}2400.nc
                    if [ -s $daysumfile ]; then
                        list="$list $daysumfile"
                    else
                        echo "Cannot find $daysumfile"
                    fi
                done
                if [ -n "$list" ]; then
                    $cdo copy $list aap.nc
                    $cdo settaxis,${yr}-${mm}-01,12:00,1day aap.nc radar_sum_$yr$mm.nc
                fi
            done
            echo "$cdo copy radar_sum_${yr}??.nc $sumfile"
            $cdo copy radar_sum_${yr}??.nc $sumfile
            rm radar_sum_${yr}??.nc
            rm -rf $yr
        fi
        if [ -s $sumfile -a ! -s ${sumfile%.nc}_latlon.nc -o ${sumfile%.nc}_latlon.nc -ot $sumfile ]; then
            echo "converting sum to latlon grid"
            # my programs do not compress yet :-(
            make km2latlon
            ./km2latlon $sumfile aap.nc
            # cut out the area with data
            $cdo selindexbox,225,482,144,466 aap.nc ${sumfile%.nc}_latlon.nc
        fi
    fi
done
$cdo copy radar_sum_20??_latlon.nc radar_sum.nc
ncatted -a title,global,a,c,"KNMI calibrated radar data" radar_sum.nc
$HOME/NINO/copyfiles.sh radar_sum.nc

# and the daily max of hourly precip

yr=2008
lastok=true
date > log
while [ $lastok = true ]; do
    yr=$((yr+1))

    zipfile=RAD_NL25_RAC_MFBS_01H_${yr}_NETCDF.zip
    wget -N http://opendap.knmi.nl/knmi/thredds/fileServer/radarprecipclim/RAD_NL25_RAC_MFBS_01H_NC/$zipfile
    if [ ! -s $zipfile ]; then
        lastok=false
    fi

    maxfile=radar_max_$yr.nc
    if [ -s $zipfile -a \( ! -s $maxfile -o $maxfile -ot $zipfile \) ]; then
        echo "unzipping $zipfile"
        unzip -q -o $zipfile
        month=0
        while [ $month -lt 12 ]; do
            month=$((month+1))
            mm=`printf %02i $month`
            if [ -d $yr/$mm ]; then
                day=0
                case $month in
                    1|3|5|7|8|10|12) dpm=31;;
                    2) dpm=28;;
                    4|6|9|11) dpm=30;;
                    *) echo "what?";exit -1;;
                esac
                if [ $dpm = 28 -a $((yr%4)) = 0 ]; then
                    dpm=29
                fi
                while [ $day -lt $dpm ]; do
                    day=$((day+1))
                    dd=`printf %02i $day`
                    echo "Processing $yr$mm$dd"
                    daymaxfile=radar_max_$yr$mm$dd.nc
                    hour=0
                    n=0
                    daylist=""
                    while [ $hour -lt 24 ]; do
                        hour=$((hour+1))
                        hh=`printf %02i $hour`
                        file=$yr/$mm/RAD_NL25_RAC_MFBS_01H_$yr$mm$dd${hh}00.nc
                        if [ -s $file ]; then
                            daylist="$daylist $file"
                            n=$((n+1))
                        fi
                    done
                    if [ $n -lt 21 ]; then # demand at least 21 valid hours, arbitrary
                        echo "skipping $yr$mm$dd, only $n time steps available"
                        echo "skipping $yr$mm$dd, only $n time steps available" >> log
                        # generate files with undefs
                        cdo divc,0. $prevdayfile $daymaxfile
                    else
                        ###echo "n=$n, daymaxfile=$daymaxfile, daylist=$daylist"
                        $cdo copy $daylist aap.nc
                        $cdo timmax aap.nc $daymaxfile
                    fi
                    $cdo settaxis,${yr}-${mm}-$dd,0:00 $daymaxfile aap.nc
                    mv aap.nc $daymaxfile
                    prevdayfile=$daymaxfile
                done
                $cdo copy radar_max_$yr$mm??.nc radar_max_$yr$mm.nc
                rm radar_max_$yr$mm??.nc
            else
                lastok=false
            fi
        done
        $cdo copy radar_max_${yr}??.nc $maxfile
        rm radar_max_${yr}??.nc
        rm -rf $yr
    fi
    if [ ! -s ${maxfile%.nc}_latlon.nc -o ${maxfile%.nc}_latlon.nc -ot $maxfile ]; then
        echo "converting max to latlon grid"
        ./km2latlon $maxfile aap.nc
        $cdo selindexbox,225,482,144,466 aap.nc ${maxfile%.nc}_latlon.nc
    fi
done
$cdo copy radar_max_20??_latlon.nc aap.nc
$cdo divc,24 aap.nc radar_max.nc
ncatted -a title,global,a,c,"KNMI calibrated radar data" -a units,pr,m,c,"mm/hr" -a long_name,pr,m,c,"daily maximum of hourly precipitation" radar_max.nc
$HOME/NINO/copyfiles.sh radar_max.nc
