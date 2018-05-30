#!/bin/sh

cdo="cdo -r -f nc4 -z zip"
for res in 25 # 05
do
    yrnow=`date +%Y`
    yr=1981 
    ## files are v2p0chirps19810101.tar.gz
    while [ $yr -le $yrnow ]; do
        # -q: quiet
        # -N: only when newer
        # -r : recursive
        # -nH: leave out the name of the server
        # --cut-dirs: start at CHIRPS-2.0

        if [ ! -s v2p0chirps_${yr}_${res}.nc -o $yr -ge $((yrnow-1)) ]; then
            echo "downloading $yr"
            wget -q -N -r -nH --cut-dirs=4 ftp://chg-ftpout.geog.ucsb.edu/pub/org/chg/products/CHIRPS-2.0/africa_daily/bils/p${res}/${yr}
            echo "converting $yr"
            date > gdal.log
            echo $yr >> gdal.log
            for file in CHIRPS-2.0/africa_daily/bils/p${res}/${yr}/*.tar.gz; do
                if [ -s $file ]; then # maybe there are none yet...
                    filename=`basename $file .tar.gz`
                    if [ ! -s $filename.hdr -o ! -s $filename.hdr ]; then
                        tar -xzf $file
                    fi
                    year=$(echo $filename | cut -c11-14)
                    if [ $yr != $year ]; then
                        echo "$0: error: wrong year: $yr != $year"
                        exit -1
                    fi
                    month=$(echo $filename | cut -c15-16)
                    day=$(echo $filename | cut -c17-18)
                    if [ ! -s ${filename}.nc -o ${filename}.nc -ot ${filename}.bil ]; then
                        gdal_translate -of NetCDF ${filename}.bil aap.nc >> gdal.log
                        ncrename -v Band1,pr aap.nc >> gdal.log
                        $cdo settaxis,${year}-${month}-${day},12:00,1day aap.nc ${filename}.nc >> gdal.log 2>&1
                        ncatted -a _FillValue,pr,m,d,-9999 -a units,pr,a,c,"mm/dy" \
                            -a long_name,pr,m,c,"precipitaton" -a axis,time,a,c,"T" \
                            -a title,global,a,c,'CHIRPS-2.0 merged satellite / rain gauge precipitation estimate' \
                            -a source,global,a,c,'ftp://chg-ftpout.geog.ucsb.edu/pub/org/chg/products/CHIRPS-2.0' ${filename}.nc
                    fi
                fi
            done
            $cdo copy v2p0chirps${yr}????.nc v2p0chirps_${yr}_${res}.nc
            if [ $HOST = bvlclim.knmi.nl -a $yr -ge 2015 ]; then
                $cdo invertlat v2p0chirps_${yr}_${res}.nc aap.nc
                mv aap.nc v2p0chirps_${yr}_${res}.nc
            fi
            rm v2p0chirps${yr}????.bil v2p0chirps${yr}????.hdr v2p0chirps${yr}????.nc
        fi # generate again?
        ((yr++))
    done # yr
	
	$cdo copy v2p0chirps_????_${res}.nc v2p0chirps_$res.nc
	file=v2p0chirps_$res.nc
	. $HOME/climexp/add_climexp_url_field.cgi
    $HOME/NINO/copyfiles.sh v2p0chirps_$res.nc
done # res(olution)

# prepend centrends for long dataset in Horn

res=25
cenfile=$HOME/climexp/UCSBData/CenTrends_v1_monthly_ce.nc
$cdo monsum v2p0chirps_$res.nc v2p0chirps_mo_${res}_tmp.nc
$cdo settaxis,1981-01-15,0:00,1month v2p0chirps_mo_${res}_tmp.nc v2p0chirps_mo_${res}.nc
ncatted -a units,pr,m,c,"mm/month" v2p0chirps_mo_$res.nc
$cdo sellonlatbox,28,54,-15,18 v2p0chirps_mo_$res.nc chirps_horn.nc
$cdo remapcon,chirps_horn.nc $cenfile centrends_$res.nc
patchfield centrends_$res.nc chirps_horn.nc none centrends_chirps.nc
file=centrends_chirps.nc
. $HOME/climexp/add_climexp_url_field.cgi
$HOME/NINO/copyfiles.sh centrends_chirps.nc