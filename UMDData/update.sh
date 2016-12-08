#!/bin/sh
# OLR

version=v02r02-1
yr=`date -d "a month ago" +%Y`
mo=`date -d "a month ago" +%m`
if [ ! -s olr-monthly_${version}-1_197901_$yr$mo.nc ]; then
    wget -q -N http://olr.umd.edu/CDR/Monthly/$version/olr-monthly_${version}_197901_$yr$mo.nc
    if [ -s olr-monthly_${version}_197901_$yr$mo.nc ]; then
        cp olr-monthly_${version}_197901_$yr$mo.nc umd_olr_mo.nc
        mv olr-monthly_${version}_197901_$yr$mo.nc aap.nc
        rm -f olr-monthly_${version}_197901_??????.nc
        mv aap.nc olr-monthly_${version}_197901_$yr$mo.nc
    fi
fi

base=ftp://eclipse.ncdc.noaa.gov/cdr/hirs-olr/daily/files/

version=v01r02
if [ ! -s downloaded_2013 ]; then
    yr=1979
    while [ $yr -le 2013 ]; do
        wget -q -N $base/olr-daily_${version}_${yr}0101_${yr}1231.nc
        ((yr++))
    done
    date > downloaded_2013
fi
if [ ! -s downloaded_2014 ]; then
    wget -q -N http://olr.umd.edu/CDR/Daily/${version}/olr-daily_${version}_20140101_20141231.nc
    date > downloaded_2014
fi
if [ ! -s downloaded_2015 ]; then
    wget -q -N http://olr.umd.edu/CDR/Daily/${version}/olr-daily_${version}_20150101_20151231.nc
    date > downloaded_2015
fi

wget -N -q http://olr.umd.edu/CDR/Daily/${version}-interim/olr-daily_${version}-preliminary_20160101_latest.nc

cdo -r -f nc4 -z zip copy olr-daily_${version}_* olr-daily_${version}-preliminary_20160101_latest.nc umd_olr_dy.nc
exit

# NDVI

d1=0
d2=11
yr=1981
ab=b
while [ $yr -lt 2007 ]; do
	file=gimms_ndvi_$yr$ab.nc
	if [ ! -s $file ]; then
		echo `date`": getting $file"
		ncks -d T,$d1,$d2 http://iridl.ldeo.columbia.edu/SOURCES/.UMD/.GLCF/.GIMMS/.NDVIg/.global/.ndvi/dods $file
	fi
	if [ ! -s $file ]; then
		echo "$0: error downloading $file, giving up"
		exit -1
	fi
	# average onto a manageable grid, combine 3x3 pixels, convert to netcdf4 with compression
	lofile=${file%.nc}_lo.nc
	if [ ! -s $lofile -o $lofile -ot $file ]; then
		echo "cdo -r -f nc4 -z zip remapcon,logrid.txt $file $lofile"
		cdo -r -f nc4 -z zip remapcon,logrid.txt $file $lofile	
	fi
	d1=$((d1+12))
	d2=$((d2+12))
	if [ $ab = a ]; then
		ab=b
	else
		ab=a
		yr=$((yr+1))
	fi
done
cdo copy gimms_ndvi_????[ab]_lo.nc gimms_ndvi_15dy.nc
daily2longerfield gimms_ndvi_15dy.nc 12 mean gimms_ndvi_mo.nc
