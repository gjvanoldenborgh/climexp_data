#!/bin/sh
wget -r -l1 -nd -A.nc -N -q http://eagle1.umd.edu/GPCP_CDR/Monthly_Data
name=`ls -t gpcp_cdr_v*.nc | head -1 | cut -b 1-16`
cdo -r -f nc4 -z zip copy ${name}*.nc gpcp_all.nc
cdo selvar,precip gpcp_all.nc gpcp.nc
ncatted -a units,precip,m,c,"mm/dy" gpcp.nc
describefield gpcp.nc
$HOME/NINO/copyfiles.sh gpcp.nc

now=`date +"%Y"`
nowm=`date +"%m"`
if [ ! -s downloaded_$now$nowm ]; then
    mkdir -p Daily_Data
    cd Daily_Data
    wget -r -l2 -nd -A .gz,.nc -N -q http://eagle1.umd.edu/GPCP_CDR/Daily_Data
    name=`ls -t gpcp_daily_cdr_v*.nc.gz | head -1 | cut -b 1-22`
    for file in ${name}*.nc.gz; do
        if [ ! -s ${file%.gz} ]; then
            gunzip -c $file > ${file%.gz}
        fi
    done
    cdo -r -f nc4 -z zip copy ${name}*.nc ../gpcp_daily.nc
    cd ..
    ncatted -a units,precip,m,c,"mm/dy" gpcp_daily.nc
    describefield gpcp_daily.nc
    $HOME/NINO/copyfiles.sh gpcp_daily.nc
    date > downloaded_$now$nowm
fi

exit
# old version

now=`date +"%Y"`
nowm=`date +"%m"`
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


BASE=http://www1.ncdc.noaa.gov/pub/data/gpcp/gpcp-v2.2/psg/gpcp_v2.2_psg
yr=1978
while [ $yr -lt $now ]; do
  yr=$((yr+1))
  wget -q -N $BASE.$yr
done
make file2dat
./file2dat
$HOME/NINO/copyfiles.sh gpcp_22.???
