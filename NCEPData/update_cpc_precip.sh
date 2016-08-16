#!/bin/sh

# daily CPC precipitation data

base=ftp://ftp.cpc.ncep.noaa.gov/precip/CPC_UNI_PRCP/GAUGE_GLB/

mkdir -p prcp
cd prcp

wget -q -N $base/RT/PRCP_CU_GAUGE_V1.0GLB_0.50deg.lnx.RT.ctl
cp PRCP_CU_GAUGE_V1.0GLB_0.50deg.lnx.RT.ctl prcp.ctl

yr=1979
yrnow=`date +%Y`
while [ $yr -le $yrnow ]; do
    if [ $yr -ge $((yrnow-1)) -o ! -s ../prcp_$yr.nc ]; then
        if [ $((yr%4)) = 0 ]; then
            n=366
        else
            n=365
        fi
        nlines=`$HOME/climexp/bin/get_index ../prcp_2015.nc 5 5 52 52 | wc -l`
        if [ $nlines != $((n+2)) ]; then
            if [ $yr -le 2005 ]; then
                dir=V1.0
            else
                dir=RT
            fi
            wget -q -N $base/$dir/$yr/PRCP_CU_GAUGE_V1.0GLB_0.50deg.lnx.${yr}*.gz
            firstfile=`ls PRCP_CU_GAUGE_V1.0GLB_0.50deg.lnx.${yr}*.gz 2> /dev/null`
            if [ -s "$firstfile" ]; then
                for file in PRCP_CU_GAUGE_V1.0GLB_0.50deg.lnx.${yr}*.gz; do
                    if [ -s $file ]; then
                        f=${file%.gz}
                        f=${f%.RT}
                        f=${f%RT}
                        if [ ! -s $f -o $f -ot $file ]; then
                            gunzip -c $file > $f
                        fi
                    fi
                    delete_rt='-e "s/.RT//"'
                done
            else
                wget -q -N $base/$dir/$yr/PRCP_CU_GAUGE_V1.0GLB_0.50deg.lnx.${yr}*RT
                delete_rt=""
            fi
            sed $delete_rt -e "s/2007/$yr/" -e "s/9999/$n/" -e "s@%y4/@@" prcp.ctl > prcp_$yr.ctl
            grads -b -l <<EOF
open prcp_$yr.ctl
set x 1 720
set y 1 360
set t 1 $n
define prcp=rain/10.
define nprcp=gnum
set sdfwrite ../prcp_$yr.nc
sdfwrite prcp
set sdfwrite ../nprcp_$yr.nc
sdfwrite nprcp
quit
EOF
            cdo -r -f nc4 -z zip settaxis,${yr}-01-01,12:00,1day ../prcp_${yr}.nc ../aap.nc
            mv ../aap.nc ../prcp_${yr}.nc
            ncatted -a units,prcp,a,c,"mm/dy" -a calendar,time,m,c,"standard" -a title,global,a,c,"NCEP/CPC global daily analysis" ../prcp_${yr}.nc
            cdo -r -f nc4 -z zip settaxis,${yr}-01-01,12:00,1day ../nprcp_${yr}.nc ../aap.nc
            mv ../aap.nc ../nprcp_${yr}.nc
            ncatted -a calendar,time,m,c,"standard" -a title,global,a,c,"NCEP/CPC global daily analysis" ../nprcp_${yr}.nc
            rm PRCP_CU_GAUGE_V1.0GLB_0.50deg.lnx.${yr}????
        fi
    fi
    yr=$((yr+1))
done
cd ..
cdo -r -f nc4 -z zip copy prcp_????.nc prcp_daily.nc
cdo -r -f nc4 -z zip copy nprcp_????.nc nprcp_daily.nc
cdo -r -f nc4 -z zip ifthen nprcp_daily.nc prcp_daily.nc prcp_daily_n1.nc
$HOME/NINO/copyfiles.sh prcp_daily.nc nprcp_daily.nc prcp_daily_n1.nc
