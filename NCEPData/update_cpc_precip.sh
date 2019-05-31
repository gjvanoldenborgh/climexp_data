#!/bin/bash
export PATH=/usr/local/free/bin/:$HOME/climexp/bin:$PATH
###echo DEBUG
###wget="echo not getting"
wget="wget -q -N"

# daily CPC precipitation data

for region in GLB CONUS; do

# this assumes we run the script at least once a year, or start from scratch
yr=`date -d "3 days ago" +%Y`
((yr1=yr-1))
if [ ! -s prcp_${region}_${yr1}.complete ]; then
    rm -f prcp_${region}_${yr1}.nc nprcp_${region}_${yr1}.nc
    # I am sure everything will go well...
    date > prcp_${region}_${yr1}.complete
fi

mkdir -p prcp
cd prcp

base=ftp://ftp.cpc.ncep.noaa.gov/precip/CPC_UNI_PRCP/GAUGE_$region/
echo "Getting .ctl file..."
case $region in
    GLB) yrbegin=1979
        res=0.50
        nx=720;ny=360;nstat=gnum
        $wget $base/RT/PRCP_CU_GAUGE_V1.0${region}_0.50deg.lnx.RT.ctl
        ;;
    CONUS) yrbegin=1948
        res=0.25
        nx=300;ny=120;nstat=nstn
        $wget $base/DOCU/PRCP_CU_GAUGE_V1.0${region}_0.25deg.lnx.RT.ctl
        ;;
esac
cp PRCP_CU_GAUGE_V1.0${region}_${res}deg.lnx.RT.ctl prcp_$region.ctl

yr=$yrbegin
yrnow=`date +%Y`
while [ $yr -le $yrnow ]; do
    if [ $yr -ge $((yrnow-1)) -o ! -s ../prcp_${region}_$yr.nc ]; then
        if [ $((yr%4)) = 0 ]; then
            n=366
        else
            n=365
        fi
        nlines=`$HOME/climexp/bin/get_index ../prcp_${region}_$yr.nc -100 -100 40 40  | wc -l`
        if [ $nlines = $((n+2)) ]; then
            echo "Skipping $region $yr"
        else
            if [ $yr -le 2005 -o \( $yr = 2006 -a $region = CONUS \) ]; then
                dir=V1.0
            else
                dir=RT
            fi
            echo "downloading $region $yr $dir..."
            echo "$wget $base/$dir/$yr/PRCP_CU_GAUGE_V1.0${region}_${res}deg.lnx.${yr}*.gz"
            $wget $base/$dir/$yr/PRCP_CU_GAUGE_V1.0${region}_${res}deg.lnx.${yr}*.gz
            firstfile=`ls PRCP_CU_GAUGE_V1.0${region}_${res}deg.lnx.${yr}*.gz | head -1 2> /dev/null`
            if [ -s "$firstfile" ]; then
                echo "Found gzipped data"
                for file in PRCP_CU_GAUGE_V1.0${region}_${res}deg.lnx.${yr}*.gz; do
                    if [ -s $file ]; then
                        f=${file%.gz}
                        f=${f%.RT}
                        f=${f%RT}
                        if [ ! -s $f -o $f -ot $file ]; then
                            gunzip -c $file > $f
                        fi
                    fi
                done
            else
                echo "No gzipped data, try uncompressed"
                echo "$wget $base/$dir/$yr/PRCP_CU_GAUGE_V1.0${region}_${res}deg.lnx.${yr}*RT"
                $wget $base/$dir/$yr/PRCP_CU_GAUGE_V1.0${region}_${res}deg.lnx.${yr}*RT
                for file in PRCP_CU_GAUGE_V1.0${region}_${res}deg.lnx.${yr}*RT; do
                    cp $file ${file%.RT}
                done
            fi
            sed -e "s/2007/$yr/" -e "s/99999/$n/" -e "s@%y4/@@" -e "s@../RT/@@" -e "s/.RT//" prcp_${region}.ctl > prcp_${region}_$yr.ctl
            echo "processing $region $yr..."
            grads -b -l > prcp_${region}_$yr.log <<EOF
open prcp_${region}_$yr.ctl
set x 1 $nx
set y 1 $ny
set t 1 $n
define prcp=rain/10.
define nprcp=$nstat
set sdfwrite ../prcp_${region}_$yr.nc
sdfwrite prcp
set sdfwrite ../nprcp_${region}_$yr.nc
sdfwrite nprcp
quit
EOF
            cdo -r -f nc4 -z zip settaxis,${yr}-01-01,12:00,1day ../prcp_${region}_${yr}.nc ../aap.nc
            mv ../aap.nc ../prcp_${region}_${yr}.nc
            ncatted -a units,prcp,a,c,"mm/dy" \
                    -a calendar,time,m,c,"standard" \
                    -a long_name,prcp,c,c,"precipitation" \
                    -a title,global,a,c,"CPC unified (gauge-based) precipitation" \
                    ../prcp_${region}_${yr}.nc
            cdo -r -f nc4 -z zip settaxis,${yr}-01-01,12:00,1day ../nprcp_${region}_${yr}.nc ../aap.nc
            mv ../aap.nc ../nprcp_${region}_${yr}.nc
            ncatted -a calendar,time,m,c,"standard" -a title,global,a,c,"CPC unified (gauge-based) precipitation" ../nprcp_${region}_${yr}.nc
            rm PRCP_CU_GAUGE_V1.0${region}_${res}deg.lnx.${yr}????
        fi
    fi
    yr=$((yr+1))
done
cd ..
echo "Concatenating $region..."
cdo -r -f nc4 -z zip copy prcp_${region}_????.nc prcp_${region}_daily.nc
ncatted -a long_name,prcp,c,c,"precipitation" prcp_${region}_daily.nc
cdo -r -f nc4 -z zip copy nprcp_${region}_????.nc nprcp_${region}_daily.nc
ncatted -a long_name,nprcp,c,c,"number of precipitation stations" nprcp_${region}_daily.nc
cdo -r -f nc4 -z zip ifthen nprcp_${region}_daily.nc prcp_${region}_daily.nc prcp_${region}_daily_n1.nc
ncatted -a long_name,prcp,m,c,"precipitation in grid boxes with observations" prcp_${region}_daily_n1.nc
for file in prcp_${region}_daily.nc nprcp_${region}_daily.nc prcp_${region}_daily_n1.nc; do
    ncatted -h -a institution,global,c,c,"NOAA/NCEP/CPC (converted to netcdf at KNMI)" \
            -a source_url,global,c,c,"ftp://ftp.cpc.ncep.noaa.gov/precip/CPC_UNI_PRCP/GAUGE_$region/" \
            -a title,global,m,c,"CPC unified (gauge-based) precipitation" \
                $file
    . $HOME/climexp/add_climexp_url_field.cgi
done
$HOME/NINO/copyfiles.sh prcp_${region}_daily.nc nprcp_${region}_daily.nc prcp_${region}_daily_n1.nc
if [ $region = CONUS ]; then
    averagefieldspace prcp_CONUS_daily.nc 2 2 prcp_CONUS_daily_05.nc
    file=prcp_CONUS_daily_05.nc
    . $HOME/climexp/add_climexp_url_field.cgi
    $HOME/NINO/copyfiles.sh prcp_CONUS_daily_05.nc
fi
done # region
