#!/bin/sh
# OLR

yrnow=`date -d "a month ago" +%Y`
base=https://www.ncei.noaa.gov/data/outgoing-longwave-radiation-daily/access/
version=v01r02
yr=1979
while [ $yr -le 2015 ]; do
    if [ ! -s downloaded_2015_final ]; then
        wget -q -N $base/olr-daily_${version}_${yr}0101_${yr}1231.nc
    fi
    ((yr++))
done
date > downloaded_2015_final 

ok=true
while [ $yr -lt $yrnow -a $ok = true ]; do
    wget -q -N http://olr.umd.edu/CDR/Daily/${version}/olr-daily_${version}_${yr}0101_${yr}1231.nc
    if [ ! -s olr-daily_${version}_${yr}0101_${yr}1231.nc ]; then
        ok=false
    else
        ((yr++))
    fi
done
ok=true
prelimfiles=""
while [ $yr -lt $yrnow -a $ok = true ]; do
    wget -q -N http://olr.umd.edu/CDR/Daily/${version}-interim/olr-daily_${version}-preliminary_${yr}0101_${yr}1231.nc
    if [ ! -s olr-daily_${version}-preliminary_${yr}0101_${yr}1231.nc ]; then
        ok=false
        echo "$0: something went wrong in retrieving http://olr.umd.edu/CDR/Daily/${version}-interim/olr-daily_${version}-preliminary_${yr}0101_${yr}1231.nc"
        exit -1
    else
        prelimfiles="$prelimfiles olr-daily_${version}-preliminary_${yr}0101_${yr}1231.nc"
        ((yr++))
    fi
done

wget -N -q http://olr.umd.edu/CDR/Daily/${version}-interim/olr-daily_${version}-preliminary_${yrnow}0101_latest.nc
prelimfiles="$prelimfiles ${version}-interim/olr-daily_${version}-preliminary_${yrnow}0101_latest.nc"
cdo -r -f nc4 -z zip copy olr-daily_${version}_????0101_????1231.nc $prelimfiles umd_olr_dy.nc
file=umd_olr_dy.nc
. $HOME/climexp/add_climexp_url_field.cgi
$HOME/NINO/copyfiles.sh umd_olr_dy.nc

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
    file=umd_olr_mo.nc
    . $HOME/climexp/add_climexp_url_field.cgi
    $HOME/NINO/copyfiles.sh umd_olr_mo.nc
fi





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
