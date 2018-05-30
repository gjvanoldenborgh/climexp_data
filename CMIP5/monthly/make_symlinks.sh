#!/bin/sh
files="$@"
exps=""
vars=""
models=""
if [ -z "$files" ]; then
	echo "usage: $0 files"
	exit -1
fi
for file in $files
do
	field=${file%.nc}
	var=${field%%_*}
	field=${field#*_}
	type=${field%%_*}
	field=${field#*_}
	model=${field%%_*}
	field=${field#*_}
	if [ ${field#p?_} != $field ]; then
		physics=${field%%_*}
		model=${model}_${physics}
		field=${field#*_}
	fi	
	exp=${field%%_*}
	###echo var=$var type=$type model=$model exp=$exp
	vars="$vars $var"
	if [ $model != one -a $model != ens -a $model != mod -a $model != modmean -a $model != modmedian ]; then
		models="$models $model"
	fi
	exps="$exps $exp"
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
for exp in $exps
do
	for var in $vars
	do
		case $var in
			?os) type=Omon;;
			mr*) type=Lmon;;
			sic) type=OImon;;
			sn?) type=LImon;;
	        cdd|altcdd|csdi|cwd|altcwd|dtr|fd|gsl|id|prcptot|r1mm|r10mm|r20mm|r95p|r99p|rx1day|rx5day|sdii|su|tn10p|tn90p|tnn|tnx|tx10p|tx90p|txn|txx|wsdi|tr) type=yr;;
			*) type=Amon;;
		esac
		for model in $models
		do
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
				nens=-1
				rm -f ${var}_${type}_${model}_${exp}_??.nc ${var}_${type}_${model}_${exp}_???.nc
				rm -f ${var}_${type}_${modelp}_${exp}_??.nc ${var}_${type}_${modelp}_${exp}_???.nc
				r=1
				while [ $r -le 16 ]
				do
					i=1
					while [ $i -lt 2 ]
					do
						if [ $type = Omon -o $type = OImon ]; then
							file=${var}_${type}_${model}_${exp}_r${r}i${i}p${p}_288.nc
						elif [ $var = z500 -o $var = z200 ]; then
							file=${var}_${type}_${model}_${exp}_r${r}i${i}p${p}_144.nc
						else
							file=${var}_${type}_${model}_${exp}_r${r}i${i}p${p}.nc
						fi
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
							link=${var}_${type}_${modelp}_${exp}_$ens.nc
							###echo "ln -s $file $link"
							ln -s $file $link
						fi
						i=$((i+1))
					done
					r=$((r+1))
				done
			p=$((p+1))
			done
		done
	done
done
