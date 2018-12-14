#!/bin/bash
###set -x

if [ "$1" != "debug" ]; then
    wget -r -l1 -nd -A.nc -N -q http://eagle1.umd.edu/GPCP_CDR/Monthly_Data
fi
name=`ls -t gpcp_cdr_v*.nc | head -1 | cut -b 1-16`
files=`ls ${name}*.nc | fgrep -v y0000`
cdo -r -f nc4 -z zip copy $files gpcp_all.nc
cdo selvar,precip gpcp_all.nc gpcp.nc
ncrename -d .nlat,latitude -d .nlon,longititude gpcp.nc
ncatted -a units,precip,m,c,"mm/dy" gpcp.nc
file=gpcp.nc
ncatted -h -a source_url,global,c,c,"http://eagle1.umd.edu/GPCP_CDR/Monthly_Data" $file
ncatted -a time_coverage_start,global,d,c,"" -a time_coverage_end,global,d,c,"" $file
. $HOME/climexp/add_climexp_url_field.cgi
$HOME/NINO/copyfiles.sh gpcp.nc

now=`date +"%Y"`
nowm=`date +"%m"`
if [ ! -s downloaded_$now$nowm ]; then
    mkdir -p Daily_Data
    cd Daily_Data
    if [ "$1" != "debug" ]; then
        wget -r -l2 -nd -A .gz,.nc -N -q http://eagle1.umd.edu/GPCP_CDR/Daily_Data
    fi
    name=`ls -t gpcp_daily_cdr_v*.nc.gz | head -1 | cut -b 1-22`
    for file in ${name}*.nc.gz; do
        if [ ! -s ${file%.gz} ]; then
            gunzip -c $file > ${file%.gz}
        fi
    done
    for file in ${name}*d[0-9][0-9].nc; do
        if [ ! -s ${file%.nc}_newgrid.nc ]; then
            cdo setgrid,../final_grid.txt ${file%.nc}.nc ${file%.nc}_tmp.nc
            # setgrid destroys the time axis it seems
            date=${file#*_y}
            yr=${date%_m*}
            date=${date#*_m}
            mo=${date%_d*}
            date=${date#*_d}
            dy=${date%.nc}
            cdo -r settaxis,${yr}-${mo}-${dy},12:00,1day ${file%.nc}_tmp.nc ${file%.nc}_newgrid.nc
            rm ${file%.nc}_tmp.nc
        fi
    done
    cdo -r -f nc4 -z zip copy ${name}*_newgrid.nc ../gpcp_daily.nc
    cd ..
    ###ncrename -d nlat,latitude -d nlon,longititude gpcp_daily.nc
    ncatted -a units,precip,m,c,"mm/dy" gpcp_daily.nc
    describefield gpcp_daily.nc
    file=gpcp_daily.nc
    ncatted -h -a source_url,global,c,c,"http://eagle1.umd.edu/GPCP_CDR/Daily_Data" $file
    ncatted -a time_coverage_start,global,d,c,"" -a time_coverage_end,global,d,c,"" $file
    . $HOME/climexp/add_climexp_url_field.cgi
    $HOME/NINO/copyfiles.sh gpcp_daily.nc
    date > downloaded_$now$nowm
fi
