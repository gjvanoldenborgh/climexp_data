#!/bin/sh
cwd=`pwd`
timescale=`basename $cwd`
if [ -z "$1" ]; then
	echo "usage: $0 all | var1 [var2 ...]"
	exit -1
elif [ "$1" = all ]; then
    if [ timescale = monthly ]; then
	    vars="tas pr tasmin tasmax evspsbl huss hurs psl rlds rlus rlut rsds rsus rsdt rsut hfss hfls pme tos taz z500 z200"
	else
	    vars="altcdd csdi altcwd dtr fd gsl id prcptot r1mm r10mm r20mm r95p r99p rx1day rx5day sdii su tn10p tn90p tnn tnx tx10p tx90p txn txx wsdi"
	fi
else
	vars="$@"
fi
if [ $timescale = monthly ]; then
    varext=""
elif [ $timescale = annual ]; then
    varext="ETCCDI"
else
    echo "$0: error: unknown timescale $timescale"
    exit -1
fi
export PATH=$HOME/bin:$PATH
if [ $timescale = "monthly" ]; then
    exps="piControl historical rcp26 rcp45 rcp60 rcp85"
    exps="historical rcp45 rcp26 rcp60 rcp85"
else
    exps="historical rcp26 rcp45 rcp60 rcp85"
fi
scp interpolate.sh make_symlinks.sh bhlclim:climexp/CMIP5/${timescale}
for var in $vars
do
	[ -f skipping_$var.log ] && rm skipping_$var.log
done
for exp in $exps
do
	echo "==== $exp ===="
	for var in $vars
	do
		# this should be co=ordinated with concatenate_years 
		# (which interpolates the Omon variables to a 288 lat/lon grid) 
		# and interpolate.sh (which interpolates the rest to a common grid)
		if [ $var = sic -o $var = tos -o $var = sos -o $var = msftmyz -o $var = msftyyz ]; then
			res=288
		else	
			res=144
		fi
		[ ! -d $var ] && mkdir $var
		if [ $var = pme ]; then
			echo "./make_pme.sh $exp"
			time ./make_pme.sh $exp
		elif [ $var = taz ]; then
			echo "./make_taz.sh $exp"
			time ./make_taz.sh $exp
		elif [ $var = z500 -o $var = z200 ]; then
			if [ $exp != historical ]; then
				level=${var#z}
				echo "./make_zg_level.sh $exp $level"
				time ./make_zg_level.sh $exp $level
			fi
		else
			echo "./concatenate_years.sh $var $exp"
			time ./concatenate_years.sh $var $exp
		fi
		if [ $? != 0 ]; then
			echo "$0: something went wrong in concatenate_years.sh"
			exit -1
		fi
		if [ $var != tauu -a $var != tauv -a $var != tos -a $var != sos -a $var != zg -a $var != ta -a $var != msftmyz -a $var != msftyyz -a $var != prw -a $var != clwvi -a ${var%cs} = $var ]; then
			rsync -L -vt -e ssh $var/${var}_*${exp}_r*i?p?.nc bhlclim:climexp/CMIP5/${timescale}/$var/
		fi
		sleep 5
		date -u > synchdate_${var}_${exp}
		firstfile=`ls $var/${var}_*${exp}_r*i?p?.nc|head -1`
		if [ -n "$firstfile" -a $var != sic -a $var != tos -a $var != sos ]; then
			echo "(cd $var; $HOME/NINO/CMIP5/${timescale}/make_symlinks.sh ${var}_\*${exp}_r\*i\?p\?.nc)"
			(cd $var; $HOME/NINO/CMIP5/${timescale}/make_symlinks.sh ${var}_*${exp}_r*i?p?.nc)
			echo "./interpolate.sh $var/${var}_\*${exp}\*p\?.nc"
			./interpolate.sh $var/${var}_*${exp}*p?.nc
		else
			echo "(cd $var; $HOME/NINO/CMIP5/${timescale}/make_symlinks.sh ${var}_\*${exp}_r\*i\?p\?_\?\?\?.nc)"
			(cd $var; $HOME/NINO/CMIP5/${timescale}/make_symlinks.sh ${var}_*${exp}_r*i?p?_???.nc)
			echo "./interpolate.sh $var/${var}_\*${exp}\*p\?_\?\?\?.nc"
			./interpolate.sh $var/${var}_*${exp}*p?_???.nc
		fi
		[ $? != 0 ] && exit -1
		if [ $var != sos -a $var != zg -a $var != ta -a $var != msftmyz -a $var != msftyyz -a $var != prw -a $var != clwvi -a ${var%cs} = $var ]; then
			realfiles=""
			symlinks=""
			for file in $var/${var}_*modmean*.nc $var/${var}_*onemean*.nc $var/${var}_*_$res.nc
			do
				onmos=`stat --printf=%N $file | fgrep -c "/data/mos"`
				if [ $onmos = 1 -o \( -f $file -a ! -L $file \) ]; then # copy as regular file
					realfiles="$realfiles $file"
				else # copy symlink
					symlinks="$symlinks $file"
				fi
			done
			[ -n "$realfiles" ] && rsync -e ssh -L -vt $realfiles bhlclim:climexp/CMIP5/${timescale}/$var/
			[ -n "$symlinks" ] && rsync -e ssh -avt $symlinks bhlclim:climexp/CMIP5/${timescale}/$var/
			if [ -n "$firstfile" -a $var != sic -a $var != tos -a $var != sos ]; then
				ssh bhlclim "cd climexp/CMIP5/${timescale}/$var; ../make_symlinks.sh ${var}_\*${exp}_r\*i\?p\?.nc"
			else
				ssh bhlclim "cd climexp/CMIP5/${timescale}/$var; ../make_symlinks.sh ${var}_\*${exp}_r\*i\?p\?_\?\?\?.nc"
			fi
			ssh bhlclim "cd climexp/CMIP5/${timescale}; ./interpolate.sh $var/${var}_\*${exp}\*.nc"
		fi
	done
done
sleep 5
cd $HOME/climexp
if [ $timescale = 'monthly' ]; then
    ext=""
else
    ext="_annual"
fi
if [ ! -s selectfield_cmip5$ext.lock ]; then
	echo "generating new file selectfield_cmip5$ext.html"
	date > selectfield_cmip5$ext.lock
  	echo "pid $$" >> selectfield_cmip5$ext.lock
  	mv selectfield_cmip5$ext.html selectfield_cmip5$ext.html.bak
  	./selectfield_cmip5.sh $timescale > selectfield_cmip5$ext.html
  	scp selectfield_cmip5$ext.html bhlclim:climexp/
  	scp selectfield_cmip5$ext.html bvlclim:climexp/
  	scp selectfield_cmip5$ext.html gj@gatotkaca.duckdns.org:climexp/
  	scp selectfield_cmip5$ext.html gj@ganesha.xs4all.nl:climexp/
  	rm selectfield_cmip5$ext.lock
else
  	echo "Another process locked selectfield_cmip5$ext.sh at "`cat selectfield_cmip5$ext.lock`
fi
