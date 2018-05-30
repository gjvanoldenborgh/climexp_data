#!/bin/sh
cwd=`pwd`
timescale=`basename $cwd`
if [ $timescale = "monthly" ]; then
    varext=""
elif [ $timescale = "annual" ]; then
    varext="ETCCDI"
else
    echo "$0: error: unnown time scale $timescale"
fi

ares=144
amap=144x72grid.txt
amap1=1x72grid.txt
ores=288
omap=288x144grid.txt

files="$@"
exps=""
vars=""
models=""
if [ -z "$files" ]; then
	echo "usage: $0 files"
	exit -1
fi
echo "$0 running on $HOST at `date`"
which cdo
cdo="cdo -f nc4 -z zip -r"
###echo DEBUG;cdo=exit
deltat=500
lwrite=false
for file in $files
do
	if [ ! -s "$file" ]; then
		echo "$0: warning : cannot find file $file"
	else
		field=`basename $file .nc`
		var=${field%%_*}
		field=${field#*_}
		type=${field%%_*}
		field=${field#*_}
		model=${field%%_*}
		if [ "${field#p?_}" != $field ]; then
			physics=${field%%_*}
			model=${model}_${physics}
			field=${field#*_}
		fi	
		field=${field#*_}
		exp=${field%%_*}
		###echo var=$var type=$type model=$model exp=$exp
		vars="$vars $var"
		if [ "$model" != one -a "$model" != ens -a "$model" != mod -a "$model" != modmean -a "$model" != modmedian ]; then
			models="$models $model"
		fi
		if [ "${exp#rcp}" != $exp -o $exp = piControl ]; then
			exps="$exps $exp"
		fi
	fi
done
exps=`echo $exps | tr " " "\n" | sort | uniq`
vars=`echo $vars | tr " " "\n" | sort | uniq`
models=`echo $models | tr " " "\n" | sort | uniq`
echo "vars	 = $vars"	| tr '\n' ' '
echo ' '
echo "models = $models" | tr '\n' ' '
echo ' '
echo "exps	 = $exps"	| tr '\n' ' '
echo ' '
if [ -z "$exps" ]; then
	echo "$0: nothing to do"
	exit
fi
for exp in $exps rcp45to85
do
	for var in $vars
	do
		remaptype=remapcon
		case $var in
			taz) type=Amon;res=$ares;map=$amap1;;
			?os) type=Omon;res=$ores;map=$omap;remaptype=remapbil;;
			mr*) type=Lmon;res=$ares;map=$amap;;
			sn?) type=LImon;res=$ares;map=$amap;;
			msft*) echo "$0: cannot interpolate $var yet";exit;;
			sic) type=OImon;res=$ores;map=$omap;remaptype=remapbil;;
			tas*|psl) type=Amon;res=$ares;map=$amap;remaptype=remapbil;;
	cdd|altcdd|csdi|cwd|altcwd|dtr|fd|gsl|id|prcptot|r1mm|r10mm|r20mm|r95p|r99p|rx1day|rx5day|sdii|su|tn10p|tn90p|tnn|tnx|tx10p|tx90p|txn|txx|wsdi|tr) type=yr;res=$ares;map=$amap;remaptype=remapbil;;
			*) type=Amon;res=$ares;map=$amap;;
		esac
		modelsused=""
		nens=-1
		nmod=-1
		none=-1 # there are cases when the required ensemble member is not there...
		rm -f $var/${var}_${type}_ens_${exp}_??.nc $var/${var}_${type}_ens_${exp}_???.nc
		rm -f $var/${var}_${type}_one_${exp}_??.nc $var/${var}_${type}_one_${exp}_???.nc
		rm -f $var/${var}_${type}_mod_${exp}_??.nc $var/${var}_${type}_mod_${exp}_???.nc
		for model in $models
		do
			###[ $model = GISS-E2-R ] && set -x
			if [ ${model#GISS} != $model ]; then
				pmax_prescribed=3
			else
				pmax_prescribed=1
			fi
			p=1
			while [ $p -le $pmax_prescribed ]
			do
				if [ ${model#GISS} != $model ]; then
					modelp=${model}_p${p}
				else
					modelp=$model
				fi
				nensmod=-1
				rm -f $var/${var}_${type}_${model}_${exp}_${res}_??.nc $var/${var}_${type}_${model}_${exp}_${res}_???.nc
				rm -f $var/${var}_${type}_${modelp}_${exp}_${res}_??.nc $var/${var}_${type}_${modelp}_${exp}_${res}_???.nc
				onefile=""
				r=1
				while [ $r -le 16 ]
				do
					i=1
					while [ $i -le 2 ]
					do
						file=$var/${var}_${type}_${model}_${exp}_r${r}i${i}p${p}.nc
						newfile=${file%.nc}_$res.nc
						if [ -s "$file" ]; then
							nens=$((nens+1))
							if [ $nens -lt 10 ]; then
								ens=00$nens
							elif [ $nens -lt 100 ]; then
								ens=0$nens
							elif [ $nens -lt 1000 ]; then
								ens=$nens
							else
								echo "$0: error: can only handle 1000 ensemble members"
								echo '${var}_${type}_${model}_${exp}_*.nc has more'
								exit -1
							fi
							nensmod=$((nensmod+1))
							if [ $nensmod -lt 10 ]; then
								ensmod=00$nensmod
							elif [ $nens -lt 100 ]; then
								ensmod=0$nensmod
							else
								ensmod=$nensmod
							fi
							pmax=$p
							imax=$i
							oldfile=$file
							# bloody MOS does not have creation dates!
							ageold=`stat -L --printf=%Y $oldfile`
							agenew=`stat -L --printf=%Y $newfile`
							agenew=$((agenew+deltat)) # often it is copied to MOS before the old file :-(
							if [ "$lwrite" = true ]; then
								echo "ageold=$ageold $oldfile"
								echo "agenew=$agenew $newfile"
							fi
							if [ ! -s $newfile -o ${agenew:-0} -lt ${ageold:-0} ]; then
								if [ $var = taz ]; then
									tafile=`echo $newfile | sed -e 's/taz/ta/g'`
									[ ! -s $file ] && echi "$0: error: cannot find $tafile" && exit -1
									echo "$cdo zonmean $tafile $newfile"
									$cdo zonmean $tafile $newfile
									if [ $oldfile -ot $tafile ]; then
										touch -r $tafile $newfile
									else
										touch -r $oldfile $newfile
									fi
								fi
							fi
							if [ ! -s $newfile -o ${agenew:-0} -lt ${ageold:-0} ]; then
								# GFDL-ESM2G only starts in 1861....
								if [ -n "$cdo_has_been_fixed" ]; then
									# crashes for netcdf4 files in cdo 1.4.1
									echo "$cdo -seldate,1861-01-01,2100-12-31 -$remaptype,$map $oldfile $newfile"
									$cdo -seldate,1861-01-01,2100-12-31 -$remaptype,$map $oldfile $newfile
								else
									tmp2file=""
									if [ $var = zg -o $var = ta -o $var = taz ]; then
										# first get rid of the extra levels to save time later on
										tmp2file=aap2_$$.nc
										echo "$cdo -intlevel,100000.00,92500.00,85000.00,70000.00,60000.00,50000.00,40000.00,30000.00,25000.00,20000.00,15000.00,10000.00,7000.00,5000.00,3000.00,2000.00,1000.00 $oldfile $tmp2file"
										$cdo -intlevel,100000.00,92500.00,85000.00,70000.00,60000.00,50000.00,40000.00,30000.00,25000.00,20000.00,15000.00,10000.00,7000.00,5000.00,3000.00,2000.00,1000.00 $oldfile $tmp2file
										oldfile=$tmp2file
									fi
									tmpfile=aap_$$.nc
									if [ $exp = piControl ]; then
										tmp2file=noot_$$.nc
										# force the start dates to be all the same
										echo "$cdo settaxis,1001-01-01,0:00,1mon $oldfile $tmpfile"
										$cdo settaxis,1001-01-01,0:00,1mon $oldfile $tmpfile
										# 200 years is the shortest piControl run (GISS)
                                        # but I need everything
										###echo "$cdo seldate,1001-01-01,1200-12-31 $tmp2file $tmpfile"
										###$cdo seldate,1001-01-01,1200-12-31 $tmp2file $tmpfile
									else
										echo "$cdo -seldate,1861-01-01,2100-12-31 $oldfile $tmpfile"
										$cdo -seldate,1861-01-01,2100-12-31 $oldfile $tmpfile
									fi
									s=$?
									if [ $s != 0 -o ! -s $tmpfile ]; then
										echo "$0: something went wrong, s=$s"
										ls -l $tmpfile
										exit -1
									fi
									# often $newfile will be a symlink pointing to 
									# the read-only NFS export of the MOS
									[ -L $newfile ] && rm $newfile
									[ $map = 1x72grid.txt ] && echo "$0: $map does not work" && exit -1
									echo "$cdo -$remaptype,$map $tmpfile $newfile"
									$cdo -$remaptype,$map $tmpfile $newfile
									rm $tmpfile
									echo "model=$model, var=$var"
									if [ ${model#GFDL} != $model -a $var != taz ]; then
										# get rid of %$#@! average_DT variable
										echo "ncks -v $var$varext $newfile $tmpfile"
										ncks -v $var$varext $newfile $tmpfile
										mv $tmpfile $newfile
									fi
								fi
							fi
							# set the date of the interpolated file equal to the orginal one
							###echo "touch -r $oldfile $newfile"
							touch -r $oldfile $newfile
							[ -n "$tmp2file" -a -f "$tmp2file" ] && rm $tmp2file
							nt=`ncdump -h $newfile | fgrep currently | sed -e 's/^.*[(]//' -e 's/ .*$//'`
							if [ $timescale = 'monthly' ]; then
							    norm=2880
							elif [ $timescale = 'annual' ]; then
							    norm=240
							else
							    echo "$0: unknown value for timescale: $timescale"
							    exit -1
							fi
							if [ $exp != piControl -a "$nt" != $norm ]; then
								echo "$0: error: $newfile has length $nt, removing"
								echo `date` "$0: error: $newfile has length $nt, removing" >> remove.log
								rm $newfile $oldfile
							else
								link=$var/${var}_${type}_ens_${exp}_$ens.nc
								newlink=$var/${var}_${type}_${modelp}_${exp}_${res}_$ensmod.nc
								###echo "ln -s ${newfile#$var/} $link / $newlink"
								# ln has funny semantics when not in the cwd...
								ln -s ${newfile#$var/} $link
								ln -s ${newfile#$var/} $newlink
							fi
						fi # does $file exist?
						if [ -s "$newfile" -o -L "$newfile" ]; then
							if [ $model = EC-EARTH ]; then # EC-EARTH again :-(
								if [ $r = 8 ]; then
									onefile=$newfile
								fi
							elif [ $model = HadGEM2-ES ]; then
								if [ $r = 2 ]; then
									onefile=$newfile
								fi
							else
								if [ $r = 1 ]; then
									onefile=$newfile
								fi
							fi
						fi
						i=$((i+1))
					done
					r=$((r+1))
				done
				files=`echo $var/${var}_${type}_${model}_${exp}_r*p${p}_${res}.nc`
				avefile=$var/${var}_${type}_${modelp}_${exp}_ave_${res}.nc
				if [ $exp != piControl ]; then
				doit=false
				foundmodel=false
				for file in $files
				do
					if [ -s $file ]; then
						if [ $foundmodel = false ]; then
							modelsused="$modelsused $model"
							foundmodel=true
						fi
						if [ ! -s $avefile -a ! -L $avefile ]; then
							doit=true
						else
							age=`stat -L --printf=%Y $file`
							ageave=`stat -L --printf=%Y $avefile`
							ageave=$((ageave+deltat)) # often it is copied to MOS before the old file :-(
							if [ "$lwrite" = true ]; then
								echo "age 0 =$age $file"
								echo "ageave=$ageave $avefile"
							fi
							if [ ${age:-0} -gt ${ageave:-0} ]; then
								doit=true
								echo "set doit to $doit, $age -gt $ageave"
							fi
						fi
					fi
				done
				if [ $doit = true ]; then
					[ -f $avefile ] && rm $avefile
					n=`echo $files | wc -w | tr -d ' '`
					if [ $n = 1 ]; then
						[ -L $avefile ] && rm $avefile
						###echo "ln -s ${files#$var/} $avefile"
						ln -s ${files#$var/} $avefile
					else
						echo "$cdo ensmean $files $avefile"
						$cdo ensmean $files $avefile
						if [ $? != 0 ]; then
							echo "$0: something went wrong"
							exit -1
						fi
						ncatted -a parent_experiment_id,global,d,, -a parent_experiment_rip,global,d,, \
								-a realization,global,m,c,"ave" $avefile
						if [ -n "$imax" -a "$imax" != 1 ]; then
							ncatted -a initialization_method,m,c,"ave" $avefile
						fi
						# adjust the date to that of the newest ingredient
						# still not waterproof but better than before
						newestfile=""
						for file in $files
						do
							if [ -z "$newestfile" -o $file -nt "$newestfile" ]; then
								newestfile=$file
							fi
						done
						###echo "touch -r $newestfile $avefile"
						touch -r $newestfile $avefile
					fi
				fi
				fi
				if [ -s $avefile ]; then
					nmod=$((nmod+1))
					if [ $nmod -lt 10 ]; then
						mod=00$nmod
					elif [ $nmod -lt 100 ]; then
						mod=0$nmod
					else
						mod=$nmod
					fi
					modlink=$var/${var}_${type}_mod_${exp}_$mod.nc
					###echo "ln -s ${avefile#$var/} $modlink"
					ln -s ${avefile#$var/} $modlink
					if [ -n "$onefile" ]; then
						none=$((none+1))
						if [ $none -lt 10 ]; then
							one=00$none
						elif [ $none -lt 100 ]; then
							one=0$none
						else
							one=$none
						fi
						onelink=$var/${var}_${type}_one_${exp}_$one.nc
						echo "ln -s ${onefile#$var/} $onelink"
						ln -s ${onefile#$var/} $onelink
					fi
				fi
				p=$((p+1))
			done # p
			###[ $model = GISS-E2-R ] && echo "DEBUG stop" && exit -1
		done # model
		if [ $exp != piControl ]; then
		### ??? firstfile=$var/${var}_${type}_mod_${exp}_000.nc
		files=$var/${var}_${type}_mod_${exp}_???.nc
		avefile=$var/${var}_${type}_modmean_${exp}_000.nc
		doit=false
		firstfile=`echo $files | tr " " "\n" | head -1`
		if [ -s "$firstfile" -a ! -s $avefile -a ! -L $avefile ]; then
			echo "$avefile does not exist; compute it"
			doit=true
		fi
		for file in $files
		do
			# and compute average only if necessary
			if [ -s $file ]; then
				age=`stat -L --printf=%Y $file`
				ageave=`stat -L --printf=%Y $avefile`
				ageave=$((ageave+10*deltat)) # often it is copied to MOS before the old file :-(
				if [ "$lwrite" = true ]; then
					echo "age 1 =$age $file"
					echo "ageave=$ageave $avefile"
				fi
				if [ ${age:-0} -gt ${ageave:-0} -a $HOST != bhlclim.knmi.nl ]; then
					echo "$file is newer than $avefile, recompute"
					doit=true
				fi
			fi
		done
		if [ $doit = true ]; then
			echo "$cdo ensmean $files $avefile"
			[ -f $avefile ] && rm $avefile
			$cdo ensmean $files $avefile
			if [ $? != 0 ]; then
				echo "$0: something went wrong"
				exit -1
			fi
			ncatted -a acknowledgements,global,d,, \
					-a references,global,d,, \
					-a institution,global,m,c,"multi-model mean computed at KNMI" \
					-a institute_id,global,d,, \
					-a model_id,global,m,c,"multi-model" \
					-a parent_experiment_id,global,d,, \
					-a parent_experiment_rip,global,d,, \
					-a contact,global,m,c,"multi-model mean computed by oldenborgh@knmi.nl" \
					-a tracking_id,global,d,, \
					-a creation_date,global,m,c,"`date -u +%Y-%m-%dT%H:%M:%SZ`" \
					-a title,global,m,c,"Multi-model mean of historical+$exp experiments of$modelsused" \
					-a parent_experiment,global,d,, \
					-a realization,global,m,c,"multi-model mean" \
					$avefile
			# adjust the date to that of the newest ingredient
			# still not waterproof but better than before
			newestfile=""
			for file in $files
			do
				if [ -z "$newestfile" -o $file -nt "$newestfile" ]; then
					newestfile=$file
				fi
			done
			###echo "touch -r $newestfile $avefile"
			touch -r $newestfile $avefile
		fi
		
		files=$var/${var}_${type}_one_${exp}_???.nc
		avefile=$var/${var}_${type}_onemean_${exp}_000.nc
		doit=false
		firstfile=`echo $files | tr " " "\n" | head -1`
		if [ -s "$firstfile" -a ! -s $avefile -a ! -L $avefile ]; then
			echo "$avefile does not exist"
			doit=true
		fi
		for file in $files
		do
			#  compute average only if necessary
			if [ -s $file ]; then
				age=`stat -L --printf=%Y $file`
				ageave=`stat -L --printf=%Y $avefile`
				ageave=$((ageave+10*deltat)) # often it is copied to MOS before the old file :-(
				if [ "$lwrite" = true ]; then
					echo "age 2 =$age $file"
					echo "ageave=$ageave $avefile"
				fi
				if [ $age -gt $ageave -a $HOST != bhlclim.knmi.nl ]; then
					echo "$file is newer than $avefile, recompute"
					doit=true
				fi
			fi
		done
		if [ $doit = true ]; then
			echo "$cdo ensmean $files $avefile"
			[ -f $avefile ] && rm $avefile
			$cdo ensmean $files $avefile
			if [ $? != 0 ]; then
				echo "$0: something went wrong"
				exit -1
			fi
			ncatted -a acknowledgements,global,d,, \
					-a references,global,d,, \
					-a institution,global,m,c,"multi-model mean (one member/model) computed at KNMI" \
					-a institute_id,global,d,, \
					-a model_id,global,m,c,"multi-model" \
					-a parent_experiment_id,global,d,, \
					-a parent_experiment_rip,global,d,, \
					-a contact,global,m,c,"multi-model mean (one member/model) computed by oldenborgh@knmi.nl" \
					-a tracking_id,global,d,, \
					-a creation_date,global,m,c,"`date -u +%Y-%m-%dT%H:%M:%SZ`" \
					-a title,global,m,c,"Multi-model mean (one member/model) of historical+$exp experiments of$modelsused" \
					-a parent_experiment,global,d,, \
					-a realization,global,m,c,"multi-model mean (one member/model)" \
					$avefile
			# adjust the date to that of the newest ingredient
			# still not waterproof but better than before
			newestfile=""
			for file in $files
			do
				if [ -z "$newestfile" -o $file -nt "$newestfile" ]; then
					newestfile=$file
				fi
			done
			###echo "touch -r $newestfile $avefile"
			touch -r $newestfile $avefile
		fi
		if [ 0 = 1 ]; then # no median
		medianfile=$var/${var}_${type}_modmedian_${exp}_00.nc
		doit=false
		for file in $files
		do
			if [ -s $file ]; then
				# if switched on, use stat to compute times...
				if [ ! -s $medianfile -o $file -nt $medianfile ]; then
					doit=true
				fi
			fi
		done
		if [ $doit = true ]; then
			echo "cdo enspctl,50 $files $medianfile"
			[ -f $medianfile ] && rm $medianfile
			cdo enspctl,50 $files $medianfile
			if [ $? != 0 ]; then
				echo "$0: something went wrong"
				exit -1
			fi
		fi
		fi # no median
        fi # not for piControl
	done
done
