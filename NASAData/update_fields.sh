#!/bin/bash
set -x
if [ "$1" = force ]; then
	force=true
else
	force=false
fi
###getit="wget -q -N"
# GISS requires HTTP/1.1, which wget does not have at the server but curl does...
getit="wget --no-check-certificate -N -q "

base=ftp://data.giss.nasa.gov/pub/gistemp/download_v3/
base=http://data.giss.nasa.gov/gistemp/sbbx/
base=https://data.giss.nasa.gov/pub/gistemp/
for file in SBBX.ERSST SBBX1880.Ts.GHCN.CL.PA.1200 SBBX1880.Ts.GHCN.CL.PA.250 # SBBX.Tsurf1200 SBBX.ERSST # SBBX.SSTHadR2
do
  cp $file $file.old
  $getit $base/$file.gz
  if [ -s $file.gz ]; then
    gunzip -c $file.gz > $file
    touch -r $file.gz $file
  fi
  c=`cat $file | wc -c`
  if [ $c -lt 10000 ]; then
  	echo "$file is too small"
  	ls -l $file
  	mv $file.old $file
  	exit -1
  fi
done

for decor in 1200 250
do
	if [ "$force" = true -o \( ! -s giss_temp_land_$decor.nc \) -o giss_temp_land_$decor.nc -ot SBBX1880.Ts.GHCN.CL.PA.$decor ]
	then
		rm TS_DATA
		ln -s SBBX1880.Ts.GHCN.CL.PA.$decor TS_DATA
		rm SST_DATA
		ln -s SBBX.ERSST SST_DATA
		yr=`date -d "last month" "+%Y"`
		sed -e "s/CURRENTYEAR/$yr/" sbbx2nc.in > sbbx2nc.f
		if [ ! -L netcdf.inc ]; then
		    [ -s /usr/include/netcdf.inc ] && ln -s /usr/include/netcdf.inc
		    [ -s /sw/include/netcdf.inc  ] && ln -s /sw/include/netcdf.inc 
		fi
		make sbbx2nc
		./sbbx2nc 0
		ncatted -h -a title,global,m,c,"GISTEMP Surface Temperature Analysis land ${decor}km" \
		        -a history,global,a,c,"Created `date` by sbbx2nc SBBX1880.Ts.GHCN.CL.PA.$decor SBBX.ERSST" gistemp.nc
		cdo -r -f nc4 -z zip copy gistemp.nc giss_temp_land_$decor.nc
		file=giss_temp_land_$decor.nc
		. $HOME/climexp/add_climexp_url_field.cgi
		rm gistemp.nc
		./sbbx2nc 1
		[ ! -L SST_DATA ] && rm SBBX.ERSST
		[ ! -s SBBX.ERSST ] && exit -1
		ncatted -h -a title,global,m,c,"GISTEMP Surface Temperature Analysis sea ${decor}km" \
		        -a history,global,a,c,"Created `date` by sbbx2nc SBBX1880.Ts.GHCN.CL.PA.$decor SBBX.ERSST" gistemp.nc
		cdo -r -f nc4 -z zip copy gistemp.nc giss_temp_sea_$decor.nc
		file=giss_temp_sea_$decor.nc
		. $HOME/climexp/add_climexp_url_field.cgi
		rm gistemp.nc
		./sbbx2nc 2
		ncatted -h -a title,global,m,c,"GISTEMP Surface Temperature Analysis land/sea ${decor}km" \
		        -a history,global,a,c,"Created `date` by sbbx2nc SBBX1880.Ts.GHCN.CL.PA.$decor SBBX.ERSST" gistemp.nc
		cdo -r -f nc4 -z zip copy gistemp.nc giss_temp_both_$decor.nc
		file=giss_temp_both_$decor.nc
		. $HOME/climexp/add_climexp_url_field.cgi
		rm gistemp.nc
		$HOME/NINO/copyfilesall.sh  giss_temp_land_$decor.nc giss_temp_both_$decor.nc
	fi
done

. ./update_ls.sh

exit

base=ftp://data.giss.nasa.gov/pub/gacp/time_ser/
yr=1981
now=`date "+%Y"`
mo=8
while [ $yr -le $now ]; do

  y=${yr##19}
  y=${y##20}
  if [ $mo -lt 10 ]; then
	m=0$mo
  else
	m=$mo
  fi

  file=$y$m.tau.ascii.gz
  if [ ! -s $file ]; then
	[ -f $file ] && rm $file
	$getit $base/$file
  fi

  file=$y$m.a.ascii.gz
  if [ ! -s $file ]; then
	[ -f $file ] && rm $file
	$getit $base/$file
  fi

  mo=$((mo + 1))
  if [ $mo -gt 12 ]; then
	mo=
	yr=$((yr + 1))
  fi
done

make gacp2gards
./gacp2grads

$HOME/NINO/copyfiles.sh gacp_*.???
