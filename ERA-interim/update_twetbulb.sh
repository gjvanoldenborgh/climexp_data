#!/bin/sh
yrnow=`date +%Y`
yr=1979
list=""
while [ -s t2m$yr.nc ]; do
    if [ ! -s twetbulb$yr.nc ]; then
        for var in tmax tdew sp; do
            case $var in
                sp) units=Pa;;
                t*) units=K;;
            esac
            c=`ncdump -h $var$yr.nc | fgrep -c "${var}:units"`
            if [ $c = 0 ]; then
                ncatted -a units,$var,a,c,"$units" $var$yr.nc
            fi
        done
        echo "wetbulb_field tmax$yr.nc tdew$yr.nc sp$yr.nc twetbulb$yr.nc"
        wetbulb_field tmax$yr.nc tdew$yr.nc sp$yr.nc twetbulb$yr.nc
    fi
    if [ -f twetbulb${yr}01.nc ]; then
        rm -f twetbulb${yr}??.nc
    fi
    ###echo $yr
    list="$list twetbulb$yr.nc"
    yr=$((yr+1))
    ###echo "checking for t2m$yr.nc"
    ###ls -l t2m$yr.nc
done
echo "t2m$yr.nc not found"

mo=1
mm=`printf %02i $mo`
while [ -s t2m$yr$mm.nc ]; do
    if [ ! -s twetbulb$yr$mm.nc ]; then
        for var in tmax tdew sp; do
            case $var in
                sp) units=Pa;;
                t*) units=K;;
            esac
            c=`ncdump -h $var$yr$mm.nc | fgrep -c "${var}:units"`
            if [ $c = 0 ]; then
                ncatted -a units,$var,a,c,"$units" $var$yr$mm.nc
            fi
        done
        echo "wetbulb_field tmax$yr$mm.nc tdew$yr$mm.nc sp$yr$mm.nc twetbulb$yr$mm.nc"
        wetbulb_field tmax$yr$mm.nc tdew$yr$mm.nc sp$yr$mm.nc twetbulb$yr$mm.nc
    fi
    ###echo $yr$mm
    list="$list twetbulb$yr$mm.nc"
    mo=$((mo+1))
    if [ $mo -gt 12 ]; then
        mo=1
        yr=$((yr+1))
    fi
    mm=`printf %02i $mo`
done
"cdo -r -f nc4 -z zip copy $list erai_twetbulb_daily.nc"
cdo -r -f nc4 -z zip copy $list erai_twetbulb_daily.nc
$HOME/NINO/copyfiles.sh erai_twetbulb_daily.nc