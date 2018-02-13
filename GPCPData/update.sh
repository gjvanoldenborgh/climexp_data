#!/bin/sh
wget -r -l1 -nd -A.nc -N -q http://eagle1.umd.edu/GPCP_CDR/Monthly_Data
name=`ls -t gpcp_cdr_v*.nc | head -1 | cut -b 1-16`
files=`ls ${name}*.nc | fgrep -v y0000`
cdo -r -f nc4 -z zip copy $files gpcp_all.nc
cdo selvar,precip gpcp_all.nc gpcp.nc
ncatted -a units,precip,m,c,"mm/dy" gpcp.nc
file=gpcp.nc
. $HOME/climexp/add_climexp_url_field.cgi
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
    file=gpcp_daily.nc
    . $HOME/climexp/add_climexp_url_field.cgi
    $HOME/NINO/copyfiles.sh gpcp_daily.nc
    date > downloaded_$now$nowm
fi
