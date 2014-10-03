#!/bin/sh
for dataset in 3A12 3B43
do
    echo $dataset
    
    lag=0
    urls=""
    while [ $lag -lt 12 ]; do
	lag=$((lag+1))
	yyyy=`date -d "$lag months ago" +%Y`
	mon=`date -d "$lag months ago" +%m`
	yy=`date -d "$lag months ago" +%y`
	doy=`date -d $yyyy-$mon-01 +%j`
	yymmdd=`date -d $yyyy-$mon-01 +%y%m%d`
	if [ $dataset = 3A12 ]
	then
	    urls="$urls http://disc2.nascom.nasa.gov/opendap/TRMM_L3/TRMM_$dataset/$yyyy/$doy/$dataset.$yymmdd.6.HDF.Z"
	else
          # N.B.:  3B43 version is 6A, not 6, and not compressed
	    urls="$urls http://disc2.nascom.nasa.gov/s4pa/TRMM_L3/TRMM_$dataset/$yyyy/$doy/$dataset.$yymmdd.6A.HDF"
	fi
    done
    for url in $urls
    do
	file=`basename $url .Z`
	file=`basename $file .HDF`.nc
	echo Extracting data from $url
	ncks -v surfaceRain_DATA_GRANULE_PlanetaryGrid $url $file
	if [ ! -s $file ]
	then
	    echo "$0: error downloading $file from $url"
	    exit -1
	fi
	# make CF-compliant :-(
	ncrename -v surfaceRain_DATA_GRANULE_PlanetaryGrid,surface_rain \
	    -v fakeDim0,lon -d fakeDim0,lon \
	    -v fakeDim1,lat -d fakeDim1,lat \
	    -v fakeDim2,lev -d fakeDim2,lev $file
	ncatted \
	    -a units,lon,m,c,"degrees_east" axis,lon,a,c,"X" \
	    -a units,lat,m,c,"degrees_north" axis,lon,a,c,"Y" \
	    # Too far away from CF... Give up
    done

  # convert to netcdf
    ./hdf2netcdf.sh ${dataset}*.HDF

done # dataset
