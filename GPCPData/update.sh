#!/bin/sh
BASE=http://www1.ncdc.noaa.gov/pub/data/gpcp/gpcp-v2.2/psg/gpcp_v2.2_psg
now=`date +"%Y"`
nowm=`date +"%m"`
yr=1978
while [ $yr -lt $now ]; do
  yr=$((yr+1))
  wget -q -N $BASE.$yr
done
make file2dat
./file2dat
$HOME/NINO/copyfiles.sh gpcp_22.???

if [ ! -s downloaded_$now$nowm ]; then
    version=1.2
    yr=1996
    mo=10
    while [ 1 ]; do
        if [ $mo -lt 10 ]; then
            date=${yr}0$mo
        else
            date=$yr$mo
        fi
        file=gpcp_1dd_v${version}_p1d.$date
        # the server sends invalid Last-Modfiied headers so it alsways downloads everything...
        if [ $yr = $now -o $nowm -le 2 -a $yr = $((now-1)) ]; then
            wget -q -N http://www1.ncdc.noaa.gov/pub/data/gpcp/1dd-v1.1/$file
        fi
        mo=$(($mo + 1))
        if [ $mo -gt 12 ]; then
            mo=$(($mo - 12))
            yr=$(($yr + 1))
        fi
        if [ ! -s $file ]; then
            break
        fi
    done

    make daily2dat
    ./daily2dat $version
    $HOME/NINO/copyfiles.sh gpcp_1dd_??.ctl gpcp_1dd_??.grd

    date > downloaded_$now$nowm
fi