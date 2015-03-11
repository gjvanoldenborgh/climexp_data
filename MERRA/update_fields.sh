#!/bin/sh
###set -x
if [ "$1" = force ]; then
	force=true
else
	force=false
fi

### The HDF is horrible (as usual)
###wget -q -r -N -nH --cut-dirs=1 ftp://goldsmr2.sci.gsfc.nasa.gov/data/s4pa/MERRA_MONTHLY/MATMNXSLV.5.2.0

yr=`date +%Y`
mo=`date +%m`
if [ force != true -a -f downloaded_$yr$mo ]; then
  echo "Already downloaded MERRA this month"
  exit
fi

# invariants
if [ ! -s lsmask.nc ]; then
	for var in FRLAKE FRLAND FRLANDICE FROCEAN; do
		ncks -v ${var} http://goldsmr2.sci.gsfc.nasa.gov/opendap/MERRA_MONTHLY/MAC0NXASM.5.2.0/1979/MERRA300.prod.assim.const_2d_asm_Nx.00000000.hdf merra_${var}.nc
		ncrename -d XDim,lon -v XDim,lon \
				-d YDim,lat -v YDim,lat merra_${var}.nc
		if [ $var = FROCEAN ]; then
			cdo mulc,-1 merra_FROCEAN.nc aap.nc
			cdo addc,1 aap.nc noot.nc
			cdo settaxis,2000-01-01,0:00,1mon noot.nc lsmask.nc
			rm aap.nc noot.nc
			ncrename -v FROCEAN,lsmask lsmask.nc
			$HOME/NINO/copyfiles.sh lsmask.nc
		fi
	done
fi

for var in t2m u10 v10 ts slp # z t u v lhtfl shtfl taux tauy wspd evap tp ci # 
do
	case $var in
		slp) eosvar=SLP;type=2D;levtype=pres;;
		z) eosvar=H;type=3D;levtype=pres;;
		t) eosvar=T;type=3D;levtype=pres;;
		u) eosvar=U;type=3D;levtype=pres;;
		v) eosvar=V;type=3D;levtype=pres;;
		slpm) eosvar=SLP;type=2D;levtype=1lev;;
		t2m) eosvar=T2M;type=2D;levtype=1lev;;
		ts) eosvar=TS;type=2D;levtype=1lev;;
		u10) eosvar=U10M;type=2D;levtype=1lev;;
		v10) eosvar=V10M;type=2D;levtype=1lev;;
		lhtfl) eosvar=EFLUX;type=2D;levtype=flux;;
		shtfl) eosvar=HFLUX;type=2D;levtype=flux;;
		evap) eosvar=EVAP;type=2D;levtype=flux;;
		taux) eosvar=TAUX;type=2D;levtype=flux;;
		tauy) eosvar=TAUY;type=2D;levtype=flux;;
		wspd) eosvar=SPEED;type=2D;levtype=flux;;
		ci) eosvar=FRSEAICE;type=2D;levtype=flux;;
		tp) eosvar=PRECTOT;type=2D;levtype=flux;;
		*) echo "$0: error: cannot handle var $var yet"; exit -1;;
	esac
	
	yr=1979
	m=1
	yrnow=`date "+%Y"`
	mnow=`date "+%m"`
	while [ $yr -le $yrnow -o $yr = $yrnow -a $m -lt $mnow ]; do
		if [ $m -lt 10 ]; then
			mo=0$m
		else
			mo=$m
		fi
		[ ! -d $yr ] && mkdir -p $yr
		file=$yr/merra_${var}_$yr$mo.nc
		if [ ! -s $file ]; then
			if [ $yr -le 1992 ]; then
				number=100
			elif [ $yr -le 2000 ]; then
				number=200
			elif [ $yr = 2010 -a $m -ge 5 -a $m -le 8 ]; then
				number=301
			else
				number=300
			fi
			if [ $levtype = 1lev ]; then
				base=http://goldsmr2.sci.gsfc.nasa.gov/opendap/MERRA_MONTHLY
				path=MATMNXSLV.5.2.0/$yr/MERRA$number.prod.assim.tavgM_2d_slv_Nx.$yr$mo.hdf
			elif [ $levtype = flux ]; then
				base=http://goldsmr2.sci.gsfc.nasa.gov/opendap/MERRA_MONTHLY
				path=MATMNXFLX.5.2.0/$yr/MERRA$number.prod.assim.tavgM_2d_flx_Nx.$yr$mo.hdf
			else
				base=http://goldsmr3.sci.gsfc.nasa.gov/opendap/MERRA_MONTHLY
				path=MAIMCPASM.5.2.0/$yr/MERRA$number.prod.assim.instM_3d_asm_Cp.$yr$mo.hdf
			fi
			ncks -v $eosvar $base/$path $file
			ncrename -v $eosvar,$var \
					-d XDim,lon -v XDim,lon \
					-d YDim,lat -v YDim,lat \
					$file
			[ $type = 3D ] && ncrename \
					-d Height,lev -v Height,lev $file
					
		fi
		m=$((m+1))
		if [ $m -gt 12 ]; then
			m=$((m-12))
			yr=$((yr+1))
		fi
	done
	cdo -f nc4 -z zip copy ????/merra_${var}_??????.nc merra_${var}.nc
	if [ $type = 2D ]; then
		$HOME/NINO/copyfiles.sh merra_${var}.nc
	else
		for lev in 850 700 500 300 200; do
			cdo sellevel,${lev}. merra_${var}.nc merra_${var}${lev}.nc
		done
		cdo zonmean merra_${var}.nc merra_${var}zon.nc
		$HOME/NINO/copyfiles.sh merra_${var}*0.nc merra_${var}zon.nc
	fi
	# to save disk space
	rm merra_${var}.nc
done

date > downloaded_$yr$mo
