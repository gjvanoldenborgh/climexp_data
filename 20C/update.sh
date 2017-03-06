#!/bin/sh

# wind speed is a chore - compuyte from 3-hourly U and V winds

base=ftp://ftp.cdc.noaa.gov/Datasets/20thC_ReanV2c/gaussian/monolevel/

yrbegin=1851
yrend=2014

for var in wspd
do
    yr=$yrbegin
    while [ $yr -le $yrend ]; do
        file=$var.10m.$yr
        echo "updating $file"
        wget -q -N $base/$file.nc
        if [ ! -s ${file}.mon.nc ]; then
            cdo -r -f nc4 -z zip monmean $file.nc ${file}.mon.nc
        fi
        if [ ! -s $file.max.nx ]; then
            cdo -r -f nc4 -z zip daymax $file.nc ${file}.max.nc
        fi
        ((yr++))
    done # yr
    cdo -r -f nc4 -z zip copy $var.10m.????.mon.nc $var.10m.mon.mean.nc
    rsync -e ssh -avt $var.10m.mon.mean.nc bhlclim:climexp/20C/
    cdo -r -f nc4 -z zip copy $var.10m.????.max.nc $var.10m.max.mean.nc
    rsync -e ssh -avt $var.10m.max.mean.nc bhlclim:climexp/20C/
done # var

echo TEMPORARY EXIT
exit

# daily mean data

base=ftp://ftp.cdc.noaa.gov/Datasets/20thC_ReanV2c/Dailies
yrbegin=1851
yrend=2014

for var in tmax.2m tmin.2m air.2m prate prmsl air
do
    if [ ! -s ${var}_daily.nc -a ! -s ${var}850_daily.nc ]; then
        case $var in
            air.2m|tmin.2m|tmax.2m|prate) dir=gaussian/monolevel;;
            prmsl) dir=monolevel;;
            air) dir=pressure;;
            *) echo "$0: error: unknown var $var";exit -1;;
        esac
        yr=$yrbegin
        while [ $yr -le $yrend ]; do
            file=$var.$yr.nc
            echo "updating $dir/$file"
            wget -q -N $base/$dir/$file
            if [ $dir = pressure ]; then
                for lev in 850; do
                    if [ ! -s ${var}${lev}.$yr.nc ]; then
                        cdo sellevel,$lev ${var}.$yr.nc ${var}${lev}.$yr.nc
                    fi
                done
            fi
            ((yr++))
        done
        if [ $dir = pressure ]; then
            for lev in 850; do
                cdo -b 32 -r -f nc4 -z zip copy $var$lev.????.nc ${var}${lev}_daily.nc
                describefield ${var}${lev}_daily.nc
                rsync -e ssh -avt ${var}${lev}_daily.nc bhlclim:climexp/20C/
            done
        else
            cdo -b 32 -r -f nc4 -z zip copy $var.????.nc ${var}_daily.nc
            describefield ${var}_daily.nc
            rsync -e ssh -avt ${var}_daily.nc bhlclim:climexp/20C/
        fi
    fi
done

exit

base=ftp://ftp.cdc.noaa.gov/Datasets/20thC_ReanV2c/Monthlies/

wget -N ftp://ftp.cdc.noaa.gov/Datasets/20thC_ReanV2c/gaussian/time_invariant/land.nc
rsync -e ssh land.nc bhlclim:climexp/20C/
###wget -N ftp://ftp.cdc.noaa.gov/Datasets/20thC_ReanV2/time_invariant/hgt.sfc.nc

for var in prmsl air.2m tmax.2m air.sfc tmin.2m prate vwnd.10m uwnd.10m wspd.10m uflx vflx icec snowc soilm lhtfl shtfl dswrf.sfc ulwrf.toa air vwnd uwnd hgt shum shum.2m rhum # rhum.2m dswrf
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
cdo -b 32 -f nc4 -z zip sub prate.mon.mean.nc evap.mon.mean.nc pme.mon.mean.nc
ncrename -v prate,pme -d x,nbnds pme.mon.mean.nc
rsync -e ssh -avt evap.mon.mean.nc pme.mon.mean.nc bhlclim:climexp/20C/
rsync -e ssh -avt evap.mon.mean.nc pme.mon.mean.nc gj@gatotkaca.duckdns.org:climexp/20C/
