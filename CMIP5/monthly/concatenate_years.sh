#!/bin/sh
cwd=`pwd`
timescale=`basename $cwd`
echo "timescale=$timescale"
var="$1"
exp="$2"
models=""
if [ -z "$var" -o -z "$exp" ]; then
	echo "usage: $0 var exp"
	exit -1
fi
cdo="cdo -f nc4 -z zip -r"
###echo DEBUG;cdo=exit
case $var in
	tos|sos|zos*|msft*|mlotst) type=Omon;;
	mr*) type=Lmon;;
	sic) type=OImon;;
	snc|snd) type=LImon;;
	cdd|altcdd|csdi|cwd|altcwd|dtr|fd|gsl|id|prcptot|r1mm|r10mm|r20mm|r95p|r99p|rx1day|rx5day|sdii|su|tn10p|tn90p|tnn|tnx|tx10p|tx90p|txn|txx|wsdi) type=yr;;
	*) type=Amon;;
esac
if [ ! -s skipping_$var.log ]; then
	echo "Missing files prevented the inclusion of:" > skipping_$var.log
fi
if [ $timescale = "monthly" ]; then
    list=`ls ethz/cmip5/$exp/${type}/$var/`
    varext=""
elif [ $timescale = "annual" ]; then
    list=`ls ftp.cccma.ec.gc.ca/data/climdex/CMIP5/$exp/`
    varext="ETCCDI"
else
    echo "$0: error: unnown time scale $timescale"
fi
models=""
for dir in $list
do
	file=`basename $dir`
	[ $file != FGOALS-s2 ] && models="$models $file"
done
echo "models = $models"
echo ' '

for model in $models
do
	r=1
	while [ $r -le 16 ]
	do
		i=1
		while [ $i -le 2 ]
		do
			p=1
			while [ $p -le 3 ]
			do
				if [ $timescale = "monthly" ]; then
				    list=ethz/cmip5/$exp/${type}/$var/$model/r${r}i${i}p${p}/${var}_${type}_${model}_${exp}_r${r}i${i}p${p}*.nc
				elif [ $timescale = "annual" ]; then
				    list=ftp.cccma.ec.gc.ca/data/climdex/CMIP5/$exp/$model/r${r}i${i}p${p}/*/*/${var}${varext}_yr_${model}_${exp}_r${r}i${i}p${p}*.nc
				else
				    echo "$0: error: unnown timescale $timescale"
				    exit -1
				fi
				outfile=$var/${var}_${type}_${model}_${exp}_r${r}i${i}p${p}.nc
				doit=false
				donotdoit=false
				if [ $model = inmcm4 -a $var = fd ]; then
					echo "Skipping $model $var, far too cold"
					donotdoit=true
				fi					
				if [ $model = CCSM4 -a $exp = piControl -a $r != 1 ]; then
					echo "Skipping CCSM4 piControl r${r}i1p1 for the time being"
					donotdoit=true
				fi
				if [ $model = CESM1-CAM5-1-FV2 -a $exp = piControl ]; then
					echo "Skipping CESM1-CAM5-1-FV2 piControl = too short"| tee -a skipping_$var.log
					donotdoit=true
				fi
				if [ $model = CMCC-CM -a $exp = piControl ]; then
					echo "Skipping CMCC-CM piControl - unknown problems"| tee -a skipping_$var.log
					donotdoit=true
				fi
				if [ $model = EC-EARTH -a $exp = piControl ]; then
					echo "Skipping EC-EARTH piControl - unknown problems"| tee -a skipping_$var.log
					donotdoit=true
				fi
				if [ ${model#GISS-E2-} != $model -a $exp = piControl -a $p = 1 ]; then
					echo "Skipping $model p1 piControl - unknown problems"| tee -a skipping_$var.log
					donotdoit=true
				fi
				if [ $model = GISS-E2-R -a $exp = piControl -a $p = 3 ]; then
					if [ ! -s ethz/cmip5/$exp/${type}/$var/$model/r${r}i${i}p${p}/${var}_${type}_${model}_${exp}_r${r}i${i}p${p}_391101-*.nc ]; then
						echo "Skipping $model $exp r${r}i1p${p} run; incomplete"
						donotdoit=true
					fi
				fi
				if [ $model = FGOALS-s2 ]; then
					# the output of this model is just too weird
					echo "Skipping FGOALS-s2: has been withdrawn"
					donotdoit=true
				fi
				if [ $model = HadCM3 -o $model = CanCM4 -o $model = MIROC4h ]; then
					# the output of this model is just too weird
					echo "Skipping $model: only control run for decadal forecasts"
					donotdoit=true
				fi
				###echo "trying $list"
				newlist=""
				for file in $list
				do
					if [ -s "$file" -a \( $file -nt $outfile -o ! -s $outfile \) ]; then
						doit=true
					fi
					if [ -s ${file%.nc}_corrected.nc -a ${file%.nc}_corrected.nc -ot $file ]; then
						echo `date` "$0: error: ${file%.nc}_corrected.nc file is older than $file, removing" >> remove.log
						rm ${file%.nc}_corrected.nc
					fi
					if [ -s ${file%.nc}_corrected.nc -a ! ${file%.nc}_corrected.nc -ot $file ]; then
						echo "skipping $file, has been corrected"
					elif [ -s $file -a $type = Lmon -a ${file%_corrected.nc} = $file ]; then
						# always correct - more than half the models have zero in 
						# the ocean (and one a slightly higher value :-()
						newfile=${file%.nc}_corrected.nc
						if [ ! -s $newfile -o $newfile -ot $file ]; then
							x=historical
							rip=r0i0p0
							m=$model
							maskfile=ethz/cmip5/$x/fx/sftlf/$m/$rip/sftlf_fx_${m}_${x}_${rip}.nc
							if [ ! -s $maskfile ]; then
								if [ ${m#CESM1} != $model -a $m != CESM1-WACCM ]; then
									m=CESM1-CAM5
								fi
								if [ $model = inmcm4 ]; then
									x=rcp45
								fi
								maskfile=ethz/cmip5/$x/fx/sftlf/$m/$rip/sftlf_fx_${m}_${x}_${rip}.nc
							fi
							if [ ! -s $maskfile ]; then
								echo "Cannot locate maskfile $maskfile"
							else
								echo "generating $model $var file with ocean values replaced by undef"
								if [ ! -s $newfile ]; then
									newlist="$newlist $newfile"
								else
									rm -f $newfile
								fi
								echo "cdo ifthen $maskfile $file $newfile"
								cdo ifthen $maskfile $file $newfile
								echo "touch -r $file $newfile"
								touch -r $file $newfile
							fi
						fi
						echo "skipping $file:, has been corrected or uncorrectable"
					elif [ -s $file -a \( $model = MIROC5 -o $model = MRI-CGCM3 \) -a $type = Omon -a ${file%_corrected.nc} = $file ]; then
						echo "generating $model $var file with zero replaced by undef"
						newfile=${file%.nc}_corrected.nc
						if [ ! -s $newfile -o $newfile -ot $file ]; then
							if [ ! -s $newfile ]; then
								newlist="$newlist $newfile"
							fi
							echo "cdo setctomiss,0. $file $newfile"
							cdo setctomiss,0. $file $newfile
							echo "touch -r $file $newfile"
							touch -r $file $newfile
						fi
					elif [ -s $file -a \( $model = CSIRO-Mk3-6-0 \) -a $var = tos -a ${file%_corrected.nc} = $file ]; then
						echo "generating $model $var file with undef under ice replaced by 271.321"
						newfile=${file%.nc}_corrected.nc
						if [ ! -s $newfile -o $newfile -ot $file ]; then
							if [ ! -s $newfile ]; then
								newlist="$newlist $newfile"
							fi
							[ -f aap.nc ] && rm aap.nc
							echo "cdo setmisstoc,271.321 $file aap.nc"
							cdo setmisstoc,271.321 $file aap.nc
							echo "cdo ifthen $HOME/climexp/CMIP5/fixed/sftof_fx_CSIRO-Mk3-6-0_historical_r0i0p0.nc aap.nc $newfile"
							cdo ifthen $HOME/climexp/CMIP5/fixed/sftof_fx_CSIRO-Mk3-6-0_historical_r0i0p0.nc aap.nc $newfile
							rm aap.nc
							echo "touch -r $file $newfile"
							touch -r $file $newfile
						fi
					elif [ -s $file -a \( $model = CMCC-CM -o $model = EC-EARTH \) -a \( $var = evspsbl \) -a ${file%_corrected.nc} = $file ]; then
						if [ $model = EC-EARTH ]; then
							describefield $file
							c=$?
							
						else
							c=0
						fi
						if [ $c != 0 ]; then
							echo "Skipping $file, wrong time axis" | tee -a skipping_${var}.log
							donotdoit=true
						else
							newfile=${file%.nc}_corrected.nc
							if [ ! -s $newfile -o $newfile -ot $file ]; then
								if [ $model = EC-EARTH -a ${file%200001-201212.nc} != $file ]; then
									# first correct time axis
									tmpfile=/tmp/`basename $file`
									echo "ncks -d time,0,71 $file $tmpfile"
									ncks -d time,0,71 $file $tmpfile
									file=$tmpfile
								fi
								echo "get_index $file 0 360 -90 90 | head -3 | tail -1 | awk '{print \$2}'"
								val1=`get_index $file 0 360 -90 90 | head -3 | tail -1 | awk '{print $2}'`
								if [ -z "$val1" ]; then
									echo "Something went wrong in get_index" | tee -a skipping_$var.log
									donotdoit=true
								else
									c=`echo $val1 | egrep -c '^ *-'`
									if [ $c = 1 ]; then
										echo "generating $model $var file sign reversed (first global mean value is $val1)" | tee -a skipping_${var}.log
										if [ ! -s $newfile ]; then
											newlist="$newlist $newfile"
										fi
										echo "cdo mulc,-1 $file $newfile"
										cdo mulc,-1. $file $newfile
										echo "touch -r $file $newfile"
										touch -r $file $newfile
									else
										echo "sign error in $model $var seems fixed, val1=$val1, adjust $0" | tee -a skipping_${var}.log
										newlist="$newlist $file"
									fi
								fi
							fi
						fi # valid time axis
					elif [ -s $file -a \( $model = IPSL-CM5A-MR -o $model = IPSL-CM5B-LR \)  -a "${var#mrro}" != $var -a ${file%_corrected.nc} = $file ]; then
						echo "generating $model $var file with mrros(s) multiplied by 48"
						newfile=${file%.nc}_corrected.nc
						if [ ! -s $newfile -o $newfile -ot $file ]; then
							if [ ! -s $newfile ]; then
								newlist="$newlist $newfile"
							fi
							val1=`get_index $file -90 90 0 360 | head -3 | tail -1 | awk '{print $2}' | scientific2decimal | tr -d ' '`
							echo "\$val1=$val1"
							echo "\${val1#0.000000}=${val1#0.000000}"
							if [ ${val1#0.000000} != $val1 ]; then
								echo "cdo mulc,48. $file $newfile"
								cdo mulc,48. $file $newfile
								echo "touch -r $file $newfile"
								touch -r $file $newfile
							else
								echo "Bug in IPSL mrro/mrros seems fixed?"
							fi
						fi
					elif [ -s $file -a $model = EC-EARTH -a $type = Omon -a ${file%_corrected.nc} = $file ]; then
						case $var in
							tos) const=273.15;;
							sos) const=0.;;
							*) echo "$0: error: what is EC-EARTH land value for $var?"; exit -1;;
						esac
						echo "generating $model $var file with land points replaced by undef"
						newfile=${file%.nc}_corrected.nc
						if [ ! -s $newfile -o $newfile -ot $file ]; then
							if [ ! -s $newfile ]; then
								newlist="$newlist $newfile"
							fi
							echo "$cdo ifthen surface_tmask.nc $file $newfile"
							$cdo ifthen surface_tmask.nc $file $newfile
							mv $newfile $newfile.bak
							echo "cdo setmissval,1e20 $newfile.bak $newfile"
							cdo setmissval,1e20 $newfile.bak $newfile
							rm $newfile.bak
							echo "touch -r $file $newfile"
							touch -r $file $newfile
						fi
					elif [ -s $file -a $model = MRI-ESM1 -a $type = Omon -a ${file%_corrected.nc} = $file ]; then
						echo "generating $model $var file with land points replaced by undef"
						newfile=${file%.nc}_corrected.nc
						if [ ! -s $newfile -o $newfile -ot $file ]; then
							if [ ! -s $newfile ]; then
								newlist="$newlist $newfile"
							fi
							echo "$cdo ifthen $file $file $newfile"
							$cdo ifthen $file $file $newfile
							echo "touch -r $file $newfile"
							touch -r $file $newfile
						fi
					elif [ $model = BNU-ESM -a $type = OImon ]; then
						echo "Skipping BNU-ESM OImon - longitude is off by 90" | tee -a skipping_$var.log
					elif [ $model = BNU-ESM -a $type = Omon ]; then
						echo "Skipping BNU-ESM Omon - longitude is off by about 80" | tee -a skipping_$var.log
					elif [ ${model#bcc-csm} != $model -a $type = OImon ]; then
						echo "Skipping bcc-csm OImon - coordinates are wrong" | tee -a skipping_$var.log
					elif [ -s $file -a ${model#CMCC} != $model -a $type = OImon -a ${file%_corrected.nc} = $file ]; then
						echo "generating $model $var file with overlap points cut out"
						newfile=${file%.nc}_corrected.nc
						if [ ! -s $newfile -o $newfile -ot $file ]; then
							if [ ! -s $newfile ]; then
								newlist="$newlist $newfile"
							fi
							echo "cdo selindexbox,2,181,1,148 $file $newfile"
							cdo selindexbox,2,181,1,148 $file $newfile
							echo "touch -r $file $newfile"
							touch -r $file $newfile
						fi
					elif [ ${model#GFDL} != $model -a $type = OImon ]; then
						echo "Skipping GFDL OImon - coordinates are wrong" | tee -a skipping_$var.log
					elif [ ${model#inmcm} != $model -a $type = OImon ]; then
						echo "Skipping inmcm4 OImon - coordinates are wrong" | tee -a skipping_$var.log
					elif [ -s $file -a $type = OImon -a ${file%_corrected.nc} = $file -a \( \
						${model#ACCESS1} != $model -o ${model#Can} != $model -o \
						${model#CCSM} != $model -o ${model#CESM} != $model -o \
						${model#CSIRO} != $model -o ${model#EC} != $model -o \
						${model#FGOALS} != $model -o ${model#GISS} != $model -o \
						${model#HadGEM2} != $model -o $model = MIROC5 -o \
						$model = MRI-CGCM3 \) ]; then
						echo "generating $model $var file with land points replaced by undef"
						newfile=${file%.nc}_corrected.nc
						if [ ! -s $newfile -o $newfile -ot $file ]; then
							if [ ! -s $newfile ]; then
								newlist="$newlist $newfile"
							fi
							if [ ${model#Can} != $model -o ${model#CSIRO} != $model -o \
								${model#GISS} != $model ]; then
								LSMASK=../fixed/not_sftlf_fx_${model}_historical_r0i0p0.nc
							else
								LSMASK=../fixed/sftof_fx_${model}_historical_r0i0p0.nc
							fi
							if [ ! -s $LSMASK ]; then
								echo "$0: error: cannot find ocean land/sea mask $LSMASK"
								exit -1
							fi
							echo "$cdo ifthen,$LSMASK $file $newfile"
							$cdo ifthen $LSMASK $file $newfile
							if [ $? != 0 -o ! -s $newfile ]; then
								echo "Something went wrong"
								exit -1
							fi
							echo "touch -r $file $newfile"
							touch -r $file $newfile
						fi
					elif [ $model = CCSM4 -a $var = sos ]; then
						echo "Skipping CCSM4 sos fields - look like nonsense" | tee -a skipping_$var.log
					elif [ $model = CCSM4 -a ${file%200501-210012.nc} != $file ]; then
						echo "skipping $file"
						newfile=${file%200501-210012.nc}200601-210012.nc
						if [ ! -s $newfile ]; then
							echo "ncks -d time,12,1151 $file $newfile"
							ncks -d time,12,1151 $file $newfile
							echo "touch -r $file $newfile"
							touch -r $file $newfile
						fi
					elif [ $model = CCSM4 -a ${file%200601-204512.nc} != $file -a -s ${file%200601-204512.nc}200601-204912.nc ]; then
						echo "skipping $file"
					elif [ $model = CCSM4 -a ${file%204601-208512.nc} != $file -a -s ${file%204601-208512.nc}205001-210012.nc ]; then
						echo "skipping $file"
					elif [ $model = CCSM4 -a ${file%208601-210012.nc} != $file -a -s ${file%208601-210012.nc}205001-210012.nc ]; then
						echo "skipping $file"
					elif [ $model = CMCC-CESM -a ${exp#rcp} != $exp -a \( ${file%200412.nc} != $file -o ${file%200512.nc} != $file \) ]; then
						echo "skipping $file"
					elif [ ${model#HadGEM2} != $model -a ${file%209911-209912.nc} != $file ]; then
						echo "skipping $file"
						newfile=${file%209911-209912.nc}209911-209911.nc
						if [ ! -s $newfile ]; then
							echo "ncks -d time,0,0 $file $newfile"
							ncks -d time,0,0 $file $newfile
							newlist="$newlist $newfile"
							echo "touch -r $file $newfile"
							touch -r $file $newfile
						fi
					elif [ $model = HadGEM2-ES -a ${file%208412-209910.nc} != $file -a $exp = piControl ]; then
						echo "skipping $file"
						newfile=${file%208412-209910.nc}208412-209711.nc
						if [ ! -s $newfile ]; then
							echo "ncks -d time,0,155 $file $newfile"
							ncks -d time,0,167 $file $newfile
							newlist="$newlist $newfile"
							echo "touch -r $file $newfile"
							touch -r $file $newfile
						fi
					elif [ -s $file -a ${file%_corrected.nc} = $file -a $model = HadGEM2-ES -a $timescale = 'annual' -a ${exp#rcp} != $exp ]; then
						echo "skipping $file"
						newfile=${file%.nc}_corrected.nc
						if [ ! -s $newfile ]; then
							# this is in fact the time axis, but cdo is confused
							# (just like climexp up to 10 minutes ago)
							echo "cdo settaxis,2005-6-1,0:00,1year $file $newfile"
							cdo settaxis,2005-6-1,0:00,1year $file $newfile
							newlist="$newlist $newfile"
							echo "touch -r $file $newfile"
							touch -r $file $newfile
						fi
					elif [ ${model} = EC-EARTH -a ${file%185001-190012.nc} != $file -a -s ${file%185001-190012.nc}190001-194912.nc ]; then
						echo "skipping $file"
						newfile=${file%185001-190012.nc}185001-189912.nc
						if [ ! -s $newfile ]; then
							echo "ncks -d time,0,599 $file $newfile"
							ncks -d time,0,599 $file $newfile
							newlist="$newlist $newfile"
							echo "touch -r $file $newfile"
							touch -r $file $newfile
						fi
					elif [ ${file%208012-209912.nc} != $file -a -f ${file%208012-209912.nc}208012-210012.nc ]; then
						echo "skipping $file"
					elif [ ${file%208012-209912.nc} != $file -a -f ${file%208012-209912.nc}208012-209911.nc ]; then
						echo "skipping $file"
					elif [ ${file%209912-210707.nc} != $file -a -f ${file%209912-210707.nc}209912-212411.nc ]; then
						echo "skipping $file"
					elif [ -s $file -a $model = FGOALS-g2 -a $var = msftmyz -a \( $r = 1 -o $r = 2 \) -a $exp = historical ]; then
						f1=${file%12.nc}
						if [ $f1 != $file ]; then
							f2=${f1%????}
							yr2=${f1#$f2}
							f3=${f2%01-}
							f4=${f3%????}
							yr1=${f3#$f4}
							echo "yr1,yr2=$yr1,$yr2"
							if [ $yr2 != $yr1 ]; then
								echo "Skipping file $file"
							else
								newlist="$newlist $file"
							fi
						else
							echo "what to do with file $file ?"
							exit -1
						fi
					else
						newlist="$newlist $file"
					fi
					if [ $file = ethz/cmip5/rcp45/Lmon/mrso/MIROC5/r3i1p1/mrso_Lmon_MIROC5_rcp45_r3i1p1_200601-210012.nc ]; then
						echo "Checking whether $file has been fixed"
						val1=`get_index $file 0 360 -90 90 | head -3 | tail -1 | awk '{print $2}'`
						if [ ${val1#1125} != $val1 ]; then
							echo "Skipping $model $var r${r}i${i}p${p} $exp, not yet fixed"
							donotdoit=true
						else
							echo "Fixed?"
						fi
					fi
				done
				[ $donotdoit = true ] && doit=false
				list=$newlist
				# check for empty files
				if [ $doit = true ]; then
					for file in $list
					do
						if [ ! -s "$file" ]; then
							doit=false
						fi
					done
				fi
				if [ $exp = historical ]; then
					# check for lists without 19th century data (I am looking at you, HadGEM2-CC)
					if [ $doit = true ]; then
						doit=false
						for file in $list
						do
							c=`echo $file | fgrep -c _18`
							if [ $c = 1 ]; then
								doit=true
							fi
						done
						if [ $doit = false ]; then
							echo `date`" $0: skipping $var $model $exp r${r}i${i}p${p}, no data in 18XX" | tee -a skipping_$var.log
						fi
					fi
					# check for lists without 21th century data (yes, this also happens a lot)
					if [ $doit = true ]; then
						doit=false
						for file in $list
						do
							c=`echo $file | egrep -c -e '-20(0[5-9]|[1-9][0-9])'`
							if [ $c = 1 ]; then
								doit=true
							fi
							done
						if [ $doit = false ]; then
							echo `date`" $0: skipping $model $var $exp r${r}i${i}p${p}, no data in 200[5-9]|20[1-9]X" | tee -a skipping_$var.log
						fi
					fi
					# and a few problem cases related to GFDL
					if [ $doit = true -a \( $model = GFDL-ESM2G -o $model = GFDL-ESM2M \) -a $timescale = monthly ]; then
						yr0=1861
						yr1=1865
						while [ $yr1 -le 2001 ]; do 
							if [ ! -s ethz/cmip5/$exp/$type/$var/$model/r${r}i${i}p${p}/${var}_${type}_${model}_${exp}_r${r}i${i}p${p}_${yr0}01-${yr1}12.nc ]; then
								doit=false
								echo `date`" $0: skipping $var $model $exp r${r}i${i}p${p}, no data in ${yr0}-${yr1}" | tee -a skipping_$var.log
							fi
							yr0=$((yr0+5))
							yr1=$((yr1+5))
						done
					fi
					if [ $doit = true -a $model = GISS-E2-R -a $timescale = monthly ]; then
						yr0=1850
						yr1=1875
						while [ $yr1 -le 2001 ]; do 
							if [ ! -s ethz/cmip5/$exp/$type/$var/$model/r${r}i${i}p${p}/${var}_${type}_${model}_${exp}_r${r}i${i}p${p}_${yr0}01-${yr1}12.nc ]; then
								doit=false
								echo `date`" $0: skipping $var $model $exp r${r}i${i}p${p}, no data in ${yr0}-${yr1}" | tee -a skipping_$var.log
							fi
							yr1=$((yr1+25))
							yr0=$((yr1-24))
						done
					fi
					if [ $doit = true -a $var = ta -a $model = CSIRO-Mk3-6-0 ]; then
						yr0=1850
						yr1=1869
						while [ $yr1 -le 2001 ]; do 
							if [ ! -s ethz/cmip5/$exp/$type/$var/$model/r${r}i${i}p${p}/${var}_${type}_${model}_${exp}_r${r}i${i}p${p}_${yr0}01-${yr1}12.nc ]; then
								doit=false
								echo `date`" $0: skipping $var $model $exp r${r}i${i}p${p}, no data in ${yr0}-${yr1}" | tee -a skipping_$var.log
							fi
							yr0=$((yr0+20))
							yr1=$((yr1+20))
							[ $yr1 = 2010 ] && yr1=2005							
						done
					fi
					if [ $doit = true  -a $model = EC-EARTH -a $r = 1 -a $timescale = monthly ]; then
						yr0=1850
						yr1=1859
						while [ $yr1 -le 2001 ]; do 
							if [ ! -s ethz/cmip5/$exp/$type/$var/$model/r${r}i${i}p${p}/${var}_${type}_${model}_${exp}_r${r}i${i}p${p}_${yr0}01-${yr1}12.nc ]; then
								doit=false
								echo `date`" $0: skipping $var $model $exp r${r}i${i}p${p}, no data in ${yr0}-${yr1}" | tee -a skipping_$var.log
							fi
							yr0=$((yr0+10))
							yr1=$((yr1+10))
						done
					fi
					if [ $doit = true -a \( $r = 2 -o $r = 9 \) -a $model = EC-EARTH -a $timescale = monthly ]; then
						yr0=1850
						yr1=1899
						while [ $yr1 -le 2001 ]; do 
							if [ ! -s ethz/cmip5/$exp/$type/$var/$model/r${r}i${i}p${p}/${var}_${type}_${model}_${exp}_r${r}i${i}p${p}_${yr0}01-${yr1}12.nc ]; then
								doit=false
								echo `date`" $0: skipping $var $model $exp r${r}i${i}p${p}, no data in ${yr0}-${yr1}" | tee -a skipping_$var.log
							fi
							yr0=$((yr0+50))
							yr1=$((yr1+50))
							[ $yr1 = 1999 ] && yr1=2012							
						done
					fi
					if [ $doit = true -a \( $var = ta -o $var = zg \) -a $model = EC-EARTH ]; then
						yr0=1850
						yr1=1899
						while [ $yr1 -le 2001 ]; do 
							if [ ! -s ethz/cmip5/$exp/$type/$var/$model/r${r}i${i}p${p}/${var}_${type}_${model}_${exp}_r${r}i${i}p${p}_${yr0}01-${yr1}12.nc ]; then
								doit=false
								echo `date`" $0: skipping $var $model $exp r${r}i${i}p${p}, no data in ${yr0}-${yr1}" | tee -a skipping_$var.log
							fi
							yr0=$((yr0+50))
							yr1=$((yr1+50))
							[ $yr1 = 2000 ] && yr1=2005							
						done
					fi
					if [ $doit = true -a \( $var = ta -o $var = zg \) -a $model = ACCESS1-3 ]; then
						yr0=1850
						yr1=1899
						while [ $yr0 -le 2000 ]; do 
							if [ ! -s ethz/cmip5/$exp/$type/$var/$model/r${r}i${i}p${p}/${var}_${type}_${model}_${exp}_r${r}i${i}p${p}_${yr0}01-${yr1}12.nc ]; then
								doit=false
								echo `date`" $0: skipping $var $model $exp r${r}i${i}p${p}, no data in ${yr0}-${yr1}" | tee -a skipping_$var.log
							fi
							yr0=$((yr0+50))
							yr1=$((yr1+50))
							[ $yr0 = 2000 ] && yr1=2005							
						done
					fi
					if [ $doit = true -a $var = zg -a $model = FGOALS-g2 ]; then
						yr0=1860
						yr1=1869
						while [ $yr0 -le 2010 ]; do 
							if [ ! -s ethz/cmip5/$exp/$type/$var/$model/r${r}i${i}p${p}/${var}_${type}_${model}_${exp}_r${r}i${i}p${p}_${yr0}01-${yr1}12.nc ]; then
								doit=false
								echo `date`" $0: skipping $var $model $exp r${r}i${i}p${p}, no data in ${yr0}-${yr1}" | tee -a skipping_$var.log
							fi
							yr0=$((yr0+10))
							yr1=$((yr1+10))
							[ $yr1 = 2019 ] && yr1=2014							
						done
					fi
					if [ $doit = true -a $var = ta -a $model = MIROC5 ]; then
						yr0=1850
						yr1=1859
						while [ $yr1 -le 2001 ]; do 
							if [ ! -s ethz/cmip5/$exp/$type/$var/$model/r${r}i${i}p${p}/${var}_${type}_${model}_${exp}_r${r}i${i}p${p}_${yr0}01-${yr1}12.nc ]; then
								doit=false
								echo `date`" $0: skipping $var $model $exp r${r}i${i}p${p}, no data in ${yr0}-${yr1}" | tee -a skipping_$var.log
							fi
							yr0=$((yr0+10))
							yr1=$((yr1+10))
							[ $yr1 = 2019 ] && yr1=2012							
						done
					fi
					if [ $doit = true -a \( $var = ta -o $var = zg \) -a $model = MRI-CGCM3 ]; then
						yr0=1850
						yr1=1859
						while [ $yr1 -le 2001 ]; do 
							if [ ! -s ethz/cmip5/$exp/$type/$var/$model/r${r}i${i}p${p}/${var}_${type}_${model}_${exp}_r${r}i${i}p${p}_${yr0}01-${yr1}12.nc ]; then
								doit=false
								echo `date`" $0: skipping $var $model $exp r${r}i${i}p${p}, no data in ${yr0}-${yr1}" | tee -a skipping_$var.log
							fi
							yr0=$((yr0+10))
							yr1=$((yr1+10))
							[ $yr1 = 2019 ] && yr1=2005							
						done
					fi
				elif [ ${exp#rcp} != $exp ]; then
					# check for lists without data starting in 200[56] (I am looking at you, GFDL-ESM2M)
					if [ $doit = true ]; then
						doit=false
						for file in $list
						do
							c=`echo $file | egrep -c '_200[56]'`
							if [ $c = 1 ]; then
								doit=true
							fi
						done
						if [ $doit = false ]; then
								echo `date`" $0: skipping $var $model $exp r${r}i${i}p${p}, no data in 200X" | tee -a skipping_$var.log
						fi
					fi
					# and a few problem cases related to GFDL
					if [ $doit = true -a ${model#GFDL} != $model -a $timescale = monthly ]; then
						yr0=2006
						yr1=2010
						while [ $yr1 -le 2100 ]; do 
							if [ ! -s ethz/cmip5/$exp/$type/$var/$model/r${r}i${i}p${p}/${var}_${type}_${model}_${exp}_r${r}i${i}p${p}_${yr0}01-${yr1}12.nc ]; then
								doit=false
								echo `date`" $0: skipping $var $model $exp r${r}i${i}p${p}, no data in ${yr0}-${yr1}" | tee -a skipping_$var.log
							fi
							yr0=$((yr0+5))
							yr1=$((yr1+5))
						done
					fi
					# and EC-EARTH
					if [ $doit = true -a $model = EC-EARTH -a $timescale = "monthly" ]; then
						if [ ! -s ethz/cmip5/$exp/$type/$var/$model/r${r}i${i}p${p}/${var}_${type}_${model}_${exp}_r${r}i${i}p${p}_*210012.nc ]; then
							doit=false
							echo `date`" $0: skipping $var $model $exp r${r}i${i}p${p}, no data in 210012" | tee -a skipping_$var.log
						fi
					fi
					# and HadGEM2
					if [ $doit = true -a $model = HadGEM2-CC -a ${var#tasm} != $var -a $exp = rcp85 ]; then
						if [ ! -s ethz/cmip5/$exp/$type/$var/$model/r${r}i${i}p${p}/${var}_${type}_${model}_${exp}_r${r}i${i}p${p}_208012-209511.nc ]; then
							doit=false
							echo `date`" $0: skipping $var $model $exp r${r}i${i}p${p}, no data in 208012-209511" | tee -a skipping_$var.log
						fi
					fi
					# and GISS E2-R
					if [ $doit = true -a $model = GISS-E2-R -a $timescale = monthly ]; then
						yr0=2006
						yr1=2025
						while [ $yr1 -le 2100 ]; do 
							if [ ! -s ethz/cmip5/$exp/$type/$var/$model/r${r}i${i}p${p}/${var}_${type}_${model}_${exp}_r${r}i${i}p${p}_${yr0}01-${yr1}12.nc ]; then
								doit=false
								echo `date`" $0: skipping $var $model $exp r${r}i${i}p${p}, no data in ${yr0}-${yr1}" | tee -a skipping_$var.log
							fi
							yr1=$((yr1+25))
							yr0=$((yr1-24))
						done
					fi
					if [ $doit = true -a $var = ta -a $model = CSIRO-Mk3-6-0 ]; then
						yr0=2006
						yr1=2025
						while [ $yr1 -le 2100 ]; do 
							if [ ! -s ethz/cmip5/$exp/$type/$var/$model/r${r}i${i}p${p}/${var}_${type}_${model}_${exp}_r${r}i${i}p${p}_${yr0}01-${yr1}12.nc ]; then
								echo "cannot find ethz/cmip5/$exp/$type/$var/$model/r${r}i${i}p${p}/${var}_${type}_${model}_${exp}_r${r}i${i}p${p}_${yr0}01-${yr1}12.nc"
								doit=false
								echo `date`" $0: skipping $var $model $exp r${r}i${i}p${p}, no data in ${yr0}-${yr1}" | tee -a skipping_$var.log
							fi
							yr1=$((yr1+20))
							yr0=$((yr1-19))
							[ $yr1 = 2105 ] && yr1=2100
						done
					fi
					if [ $doit = true -a $var = zg -a $model = MRI-CGCM3 ]; then
						yr0=2006
						yr1=2015
						while [ $yr0 -lt 2100 ]; do 
							if [ ! -s ethz/cmip5/$exp/$type/$var/$model/r${r}i${i}p${p}/${var}_${type}_${model}_${exp}_r${r}i${i}p${p}_${yr0}01-${yr1}12.nc ]; then
								echo "cannot find ethz/cmip5/$exp/$type/$var/$model/r${r}i${i}p${p}/${var}_${type}_${model}_${exp}_r${r}i${i}p${p}_${yr0}01-${yr1}12.nc"
								doit=false
								echo `date`" $0: skipping $var $model $exp r${r}i${i}p${p}, no data in ${yr0}-${yr1}" | tee -a skipping_$var.log
							fi
							yr1=$((yr1+10))
							yr0=$((yr0+10))
							[ $yr1 -gt 2100 ] && yr1=2100
						done
					fi
					if [ $doit = true -a \( $var = zg -o $var = ta \) -a $model = MIROC5 ]; then
						yr0=2006
						yr1=2009
						while [ $yr0 -lt 2100 ]; do 
							if [ ! -s ethz/cmip5/$exp/$type/$var/$model/r${r}i${i}p${p}/${var}_${type}_${model}_${exp}_r${r}i${i}p${p}_${yr0}01-${yr1}12.nc ]; then
								echo "cannot find ethz/cmip5/$exp/$type/$var/$model/r${r}i${i}p${p}/${var}_${type}_${model}_${exp}_r${r}i${i}p${p}_${yr0}01-${yr1}12.nc"
								doit=false
								echo `date`" $0: skipping $var $model $exp r${r}i${i}p${p}, no data in ${yr0}-${yr1}" | tee -a skipping_$var.log
							fi
							yr1=$((yr1+10))
							yr0=$((yr1-9))
						done
					fi
					if [ $doit = true -a \( $var = zg -o $var = ta \) -a $model = MPI-ESM-MR ]; then
						yr0=2006
						yr1=2009
						while [ $yr0 -lt 2100 ]; do 
							if [ ! -s ethz/cmip5/$exp/$type/$var/$model/r${r}i${i}p${p}/${var}_${type}_${model}_${exp}_r${r}i${i}p${p}_${yr0}01-${yr1}12.nc ]; then
								echo "cannot find ethz/cmip5/$exp/$type/$var/$model/r${r}i${i}p${p}/${var}_${type}_${model}_${exp}_r${r}i${i}p${p}_${yr0}01-${yr1}12.nc"
								doit=false
								echo `date`" $0: skipping $var $model $exp r${r}i${i}p${p}, no data in ${yr0}-${yr1}" | tee -a skipping_$var.log
							fi
							yr1=$((yr1+10))
							yr0=$((yr1-9))
							[ $yr0 = 2090 ] && yr1=2100
						done
					fi
					if [ $doit = true -a $model = CMCC-CESM ]; then
						yr0=2006
						yr1=2015
						while [ $yr0 -lt 2100 ]; do 
							if [ ! -s ethz/cmip5/$exp/$type/$var/$model/r${r}i${i}p${p}/${var}_${type}_${model}_${exp}_r${r}i${i}p${p}_${yr0}01-${yr1}12.nc ]; then
								echo "cannot find ethz/cmip5/$exp/$type/$var/$model/r${r}i${i}p${p}/${var}_${type}_${model}_${exp}_r${r}i${i}p${p}_${yr0}01-${yr1}12.nc"
								doit=false
								echo `date`" $0: skipping $var $model $exp r${r}i${i}p${p}, no data in ${yr0}-${yr1}" | tee -a skipping_$var.log
							fi
							yr1=$((yr1+10))
							yr0=$((yr1-9))
							[ $yr0 = 2096 ] && yr1=2100
						done
					fi
					# and bcc-cm1-1 and HadGEM2-??
					if [ $doit = true ]; then
						if [ ! -s ethz/cmip5/$exp/$type/$var/$model/r${r}i${i}p${p}/${var}_${type}_${model}_${exp}_r${r}i${i}p${p}_210001-*.nc -a \
							-s ethz/cmip5/$exp/$type/$var/$model/r${r}i${i}p${p}/${var}_${type}_${model}_${exp}_r${r}i${i}p${p}_*-209912.nc \
							]; then
							doit=false
							echo `date`" $0: skipping $var $model $exp r${r}i${i}p${p}, file *-209912 exists but 210001-* does not" | tee -a skipping_$var.log
						fi
						if [ ! -s ethz/cmip5/$exp/$type/$var/$model/r${r}i${i}p${p}/${var}_${type}_${model}_${exp}_r${r}i${i}p${p}_209912-*.nc -a \
							-s ethz/cmip5/$exp/$type/$var/$model/r${r}i${i}p${p}/${var}_${type}_${model}_${exp}_r${r}i${i}p${p}_*-209911.nc \
							]; then
							doit=false
							echo `date`" $0: skipping $var $model $exp r${r}i${i}p${p}, file *-209911 exists but 209912-* does not" | tee -a skipping_$var.log
						fi
						if [ \( -s ethz/cmip5/$exp/$type/$var/$model/r${r}i${i}p${p}/${var}_${type}_${model}_${exp}_r${r}i${i}p${p}_*-210011.nc \
							\) -a ! \( -s ethz/cmip5/$exp/$type/$var/$model/r${r}i${i}p${p}/${var}_${type}_${model}_${exp}_r${r}i${i}p${p}_210012-*.nc \
							\) ]; then
							doit=false
							echo `date`" $0: skipping $var $model $exp r${r}i${i}p${p}, file *-210011 exists but 210012-* does not" | tee -a skipping_$var.log
						fi
					fi
				fi
				if [ $doit = true ]; then
					if [ ${exp#rcp} != $exp ]; then
						# prepend the historical run, truncated to dec2005 (many go further)
		 				if [ ${model#GFDL} != $model -a -s $var/${var}_${type}_${model}_historical_r${r}i${i}p${p}.nc -a $timescale = monthly ]; then
		 					histlist=""
			 				for file in ethz/cmip5/historical/${type}/$var/$model/r${r}i${i}p${p}/${var}_${type}_${model}_historical_r${r}i${i}p${p}*.nc
			 				do
			 					if [ ! -s ${file%.nc}_corrected.nc ]; then
			 						histlist="$histlist $file"
			 					fi
			 				done
			 				list="$histlist $list"
						else
							histfile=$var/${var}_${type}_${model}_historical_r${r}i${i}p${p}.nc
							if [ -s $histfile ]; then
								case $model in
									*)	   year=2005;;
								esac
								yrend=`describefield $histfile 2>&1 | fgrep "available" | sed -e 's/^.* to //' -e 's/ [(].*//'`
								if [ $timescale = 'monthly' ]; then
    								if [ ${model#Had} != $model -a $model != HadGEM2-AO ]; then
	    								month=Nov;mo=11
		    						else
			    						month=Dec;mo=12
				    				fi
				    			elif [ $timescale = 'annual' ]; then
    								if [ ${model#Had} != $model -a $model != HadGEM2-AO ]; then
    									month="";mo=12;year=2004
    								else
					    			    month="";mo=12
									fi
				    			else
				    			    echo "$0: error: unknown timescale2 $timescale"
				    			    exit -1
				    			fi
								echo "yrend=$yrend, should be $month$year"
								if [ -z "$yrend" ]; then
									echo "$0: error: something is wrong with $histfile"
									exit -1
								fi
								if [ $yrend = $month$year ]; then
									truncfile=$histfile
								else
									truncfile=${histfile%.nc}_upto$year.nc
									if [ ! -s $truncfile -o $truncfile -ot $histfile ]; then
										echo "$cdo seldate,1850-01-01,${year}-${mo}-31 $histfile $truncfile"
										$cdo seldate,1850-01-01,${year}-${mo}-31 $histfile $truncfile
									fi
								fi
								list="$truncfile $list"
							else
								doit=false
							fi
						fi
					fi
					if [ $doit = true ]; then
						[ -L $outfile ] && rm $outfile
						echo $cdo copy $list $outfile
						$cdo copy $list $outfile
						if [ ! -s $outfile ]; then
							echo "Something went wrong in cdo copy"
							exit -1
						fi
						if [ ${exp#rcp} != $exp ]; then
							# adjust the metadata to be that of the RCP run
							if [ $timescale = "monthly" ]; then
    							firstfile=`ls  ethz/cmip5/$exp/${type}/$var/$model/r${r}i${i}p${p}//${var}_${type}_${model}_${exp}_r${r}i${i}p${p}*.nc | head -1`
    					    elif [ $timescale = "annual" ]; then
    							firstfile=`ls  ftp.cccma.ec.gc.ca/data/climdex/CMIP5/$exp/$model/r${r}i${i}p${p}/*/*/${var}${varext}_yr_${model}_${exp}_r${r}i${i}p${p}*.nc | head -1`
    					    else
    					        echo "$0: error: unknown timescale4 $timescale"
    					        exit -1
    					    fi
							ncdump -h $firstfile > /tmp/metadata$$.cdl
							ncattedargs=`cat /tmp/metadata$$.cdl \
								| sed \
								-e '/{/,/global attributes/d' \
								-e '/licence/,/;$/d' \
								-e '/history/,/;$/d' \
								-e '/references/,/;$/d' \
								-e '/acknowledgements/,/;$/d' \
								-e '/forcing_note/,/;$/d' \
								-e '/}/d' \
								-e 's/^[ 	\t]*:/ -a /' \
								-e 's/ experiment_id = "/ experiment_id,global,o,c,"historical+/' \
								-e 's/ = "/,global,o,c,"/' \
								-e 's/time = /time,global,o,f,/' \
								-e 's/ = /,global,o,s,/' \
								-e 's/" ;/"/' \
								-e 's/ ;//' \
								| tr '\n' " "  `
							ncattedargs="-h $ncattedargs $outfile"
							echo "ncatted $ncattedargs" > /tmp/aap$$.sh
							sh /tmp/aap$$.sh
							if [ $? != 0 ]; then
								echo "$0: something went wrong in running aap$$.sh "
								cat /tmp/aap$$.sh
								###rm $outfile
								exit -1
							fi
							rm /tmp/aap$$.sh /tmp/metadata$$.cdl
						fi
						if [ $model#GFDL} != $model -a $var = msftyyz ]; then
							# ^%^#$&% cdo adds X axis attributes for some reason
							echo "ncatted -a standard_name,basin,d,, -a long_name,basin,d,, -a units,basin,d,, -a axis,basin,d,, $outfile"
							ncatted -a standard_name,basin,d,, -a long_name,basin,d,, -a units,basin,d,, -a axis,basin,d,, $outfile
						fi
						# adjust the date to that of the newest ingredient
						# still not waterproof but better than before
						newestfile=""
						for file in $list
						do
							if [ -z "$newestfile" -o $file -nt "$newestfile" ]; then
								newestfile=$file
							fi
						done
						echo "touch -r $newestfile $outfile"
						touch -r $newestfile $outfile
						# finally
						describefield $outfile >& /tmp/d$$.txt
						s=$?
						c=`fgrep -c "irregular time axis" /tmp/d$$.txt`
						if [ $timescale = "monthly" ]; then
    						n=`fgrep available /tmp/d$$.txt | cut -b 49-53`
    						norm=1260
    					elif [ $timescale = "annual" ]; then
    						n=`fgrep available /tmp/d$$.txt | cut -b 42-46`
    						norm=105
    				    else
    				        echo "$0: error: unknown timeacale $timescale"
    				        exit -1
    				    fi
						n=${n% }
						echo "s=$s,c=$c,n=$n"
						if [ "$s" != 0 -o "$c" != 0 -o -z "$n" ]; then
							cat /tmp/d$$.txt
							rm	/tmp/d$$.txt
							mv $outfile $outfile.wrong
							echo "$0: something went wrong in constructing $outfile, status=$s, irregular time axis=$c, available=$n"
							exit -1
						fi
						if [ "$n" != '****' -a "$n" -lt $norm ]; then
							cat /tmp/d$$.txt
							rm	/tmp/d$$.txt
							mv $outfile $outfile.wrong
							echo "$0: something went wrong in constructing $outfile, only $n time steps"
							exit -1
						fi
						rm /tmp/d$$.txt
					fi
				fi
				if [ -s "$outfile" -a $exp = piControl ]; then
					newfile=${outfile%.nc}_shifted.nc
					if [ ! -s $newfile -o $newfile -ot $outfile ]; then
						echo "cdo settaxis,1000-01-01,0:00,1mon $outfile $newfile"
						cdo settaxis,1000-01-01,0:00,1mon $outfile $newfile
					fi
				fi							
				if [ $type = OImon -o $type = Omon -a $var != msftmyz -a $var != msftyyz ]; then
					# most sea ice and some ocean fields are on a curvilinear grid, so do interpolation here.
					# coordinate begindate and enddate with interpolate.sh :-(
					latlonfile=${outfile%.nc}_288.nc
					# Bloody MOS does not have a creation date!!!
					if [ -s $outfile ]; then
						ageout=`stat -L --printf=%Y $outfile`
						agelatlon=`stat -L --printf=%Y $latlonfile`
						agelatlon=$((agelatlon+20)) # often it is copied to MOS before the other outfile :-(
					else
						ageout=0
						agelatlon=0
					fi
					if [ -s $outfile -a \( ! -s $latlonfile -o ${agelatlon:-0} -lt ${ageout:-0} \) ]; then
						tmpfile=/tmp/tmp$$.nc
						if [ ${exp#rcp} != $exp ]; then
							enddate=2100-12-31
						else
							enddate=2005-12-31
						fi
						echo "$cdo -seldate,1861-01-01,$enddate $outfile $tmpfile"
						$cdo -seldate,1861-01-01,$enddate $outfile $tmpfile
						[ -f $latlonfile ] && rm $latlonfile
						if [ ${model#CMCC} != $model ]; then
							remap="-remapnn"
							[ -f aap$$.nc ] && rm aap$$.nc
							echo "cdo selindexbox,2,181,1,148 $tmpfile aap$$.nc"
							cdo selindexbox,2,181,1,148 $tmpfile aap$$.nc
							mv aap$$.nc $tmpfile
						elif [ ${model#GFDL} != $model ]; then
							remap=remapnn
						else
							remap=remapbil
						fi
						echo "$cdo $remap,288x144grid.txt $tmpfile $latlonfile"
						$cdo $remap,288x144grid.txt $tmpfile $latlonfile
						outfile=$latlonfile
						rm $tmpfile
						if [ ${model#GFDL} != $model ]; then
							ncks -v $var $latlonfile $tmpfile
							mv $tmpfile $latlonfile
						fi
						echo "touch -r $outfile $latlonfile"
						touch -r $outfile $latlonfile
						nt=`ncdump -h $latlonfile | fgrep currently | sed -e 's/^.*[(]//' -e 's/ .*$//'`
						if [ ${exp#rcp} != $exp -a "$nt" != 2880 ]; then
							echo "$0: error: $latlonfile has length $nt, removing"
							echo `date` "$0: error: $latlonfile has length $nt, removing" >> remove.log
							rm $latlonfile
						fi
					fi
				fi
				p=$((p+1))
			done
			i=$((i+1))
		done
		r=$((r+1))
	done
done
