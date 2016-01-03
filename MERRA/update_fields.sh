#!/bin/sh
###set -x
if [ "$1" = force ]; then
	force=true
else
	force=false
fi

yr=`date +%Y`
mo=`date +%m`
if [ force != true -a -f downloaded_$yr$mo ]; then
  echo "Already downloaded MERRA this month"
  exit
fi

# invariants
if [ ! -s lsmask.nc ]; then
	for var in FRLAKE FRLAND FRLANDICE FROCEAN; do
	    url=http://goldsmr4.sci.gsfc.nasa.gov:80/opendap/MERRA2_MONTHLY/M2C0NXASM.5.12.4/1980/MERRA2_100.const_2d_asm_Nx.00000000.nc4
		ncks -v ${var} ${url} merra_${var}.nc
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

for var in z t u v t2m u10 v10 ts slp lhtfl shtfl taux tauy wspd evap tp ci 
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
	
	yr=1980
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
		    if [ $yr -le 1991 ]; then
    			number=100
    		elif [ $yr -le 2000 ]; then
    		    number=200
    		elif [ $yr -le 2010 ]; then
    		    number=300
    		else
    		    number=400
    		fi
			if [ $levtype = 1lev ]; then
				base=http://goldsmr4.sci.gsfc.nasa.gov:80/opendap/MERRA2_MONTHLY
				path=M2TMNXSLV.5.12.4/$yr/MERRA2_$number.tavgM_2d_slv_Nx.$yr$mo.nc4
			elif [ $levtype = flux ]; then
				base=http://goldsmr4.sci.gsfc.nasa.gov:80/opendap/MERRA2_MONTHLY
				path=M2TMNXFLX.5.12.4/$yr/MERRA2_$number.tavgM_2d_flx_Nx.$yr$mo.nc4
			elif [ $levtype = pres ]; then
				base=http://goldsmr5.sci.gsfc.nasa.gov:80/opendap/MERRA2_MONTHLY
				path=M2IMNPASM.5.12.4/$yr/MERRA2_$number.instM_3d_asm_Np.$yr$mo.nc4
			else
				base=http://goldsmr4.sci.gsfc.nasa.gov:80/opendap/MERRA2_MONTHLY
				path=M2IMNXASM.5.12.4/$yr/MERRA2_$number.instM_2d_asm_Nx.$yr$mo.nc4
			fi
			use_cdo=false
			use_nco=false
			if [ $use_cdo = true ]; then
    			cdo selvar,$eosvar $base/$path $file
    			exit
    		elif [ $use_nco = true ]; then
	    		ncks -v $eosvar $base/$path $file
	    	else
	    	    mkdir -p MERRA2_MONTHLY/`dirname $path`
	    	    if [ $levtype = pres ]; then
	    	        base=ftp://goldsmr5.sci.gsfc.nasa.gov/data/s4pa/MERRA2_MONTHLY
	    	    else
	    	        base=ftp://goldsmr4.sci.gsfc.nasa.gov/data/s4pa/MERRA2_MONTHLY
	    	    fi
	    	    (cd MERRA2_MONTHLY/`dirname $path`; wget -q -N $base/$path)
	    	    cdo -f nc4 -z zip selvar,$eosvar MERRA2_MONTHLY/$path $file
	    	    if [ $var = v ]; then
	    	        rm MERRA2_MONTHLY/$path
	    	    fi
	    	fi
			ncrename -v $eosvar,$var $file
			[ $type = 3D ] && ncrename \
					-d Height,lev -v Height,lev $file
					
		fi
		m=$((m+1))
		if [ $m -gt 12 ]; then
			m=$((m-12))
			yr=$((yr+1))
		fi
	done
	cdo -b 32 -f nc4 -z zip copy ????/merra_${var}_??????.nc merra_${var}.nc
	describefield merra_${var}.nc
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
	###rm merra_${var}.nc
done

date > downloaded_$yr$mo
