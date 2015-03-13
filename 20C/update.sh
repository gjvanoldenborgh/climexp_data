#!/bin/sh

if [ 0 = 1 ]; then
base=ftp://ftp.cdc.noaa.gov/Datasets/20thC_ReanV2/Monthlies/

wget -N ftp://ftp.cdc.noaa.gov/Datasets/20thC_ReanV2/gaussian/time_invariant/land.nc
###wget -N ftp://ftp.cdc.noaa.gov/Datasets/20thC_ReanV2/time_invariant/hgt.sfc.nc

for var in prmsl air.2m tmax.2m air.sfc tmin.2m prate vwnd.10m uwnd.10m wspd.10m uflx vflx icec snowc soilm lhtfl shtfl uswrf.sfc ulwrf.sfc air vwnd uwnd hgt shum shum.2m rhum # rhum.2m dswrf
do

  case $var in
	  prmsl) dir=monolevel;;
	  *.2m|air.sfc|prate|?wnd.10m|wspd.10m|?flx|icec|snowc|soilm|?htfl|u?wrf.sfc|d?wrf.sfc|?hum.2m) dir=gaussian/monolevel;;
	  air|?wnd|hgt|?hum) dir=pressure;;
	  *) echo "do not know about $var yet"; exit -1;;
  esac
  
  wget -N $base/$dir/$var.mon.mean.nc

  if [ $dir = pressure ]; then
	  for level in 200 300 500 700 850
	  do
		if [ $var.mon.mean.nc -nt $var$level.nc ]; then
			ncks -O -d level,$level. $var.mon.mean.nc $var$level.nc
		fi
		rsync -v -e ssh $var$level.nc bhlclim:climexp/20C/
	  done
  else
	  rsync -v -e ssh $var.mon.mean.nc bhlclim:climexp/20C/
  fi
done
./make_snao.sh
fi

for var in prmsl air.2m tmax.2m prate vwnd.10m uwnd.10m wspd.10m icec snowc soilm lhtfl shtfl uswrf.sfc ulwrf.sfc
do
	rsync -v -e ssh $var.mon.mean.nc gj@gatotkaca.duckdns.org:climexp/20C/
done
for var in air hgt
do
	for level in 200 500
	do
		rsync -v -e ssh ${var}$level.nc gj@gatotkaca.duckdns.org:climexp/20C/
	done
done

cdo -b 32 -f nc4 -z zip divc,2260000 lhtfl.mon.mean.nc evap.mon.mean.nc
ncrename -v lhtfl,evap -d x,nbnds evap.mon.mean.nc
ncatted -a units,evap,m,c,"kg m-2 s-1" evap.mon.mean.nc
cdo -b -f nc4 -z zip 32 sub prate.mon.mean.nc evap.mon.mean.nc pme.mon.mean.nc
ncrename -v prate,pme -d x,nbnds pme.mon.mean.nc
rsync -e ssh -avt evap.mon.mean.nc pme.mon.mean.nc bhlclim:climexp/20C/
rsync -e ssh -avt evap.mon.mean.nc pme.mon.mean.nc gj@gatotkaca.duckdns.org:climexp/20C/
