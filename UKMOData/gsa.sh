#!/bin/sh
# coordinate with ~/NINO/THOR/gsa.sh
for file in salt_EN3_v2a_ObjectiveAnalysis_*.nc
do
	f=`basename $file .nc`
	series=${f}_subpolar.dat
	if [ ! -f $series -o $series -ot $file ]; then
		echo $file
		get_index $file -65 0 50 65 > $series
	fi
	series=${f}_nordic.dat
	if [ ! -f $series -o $series -ot $file ]; then
		echo $file
		get_index $file -35 25 65 80 > $series
	fi
	series=${f}_labrador.dat
	if [ ! -f $series -o $series -ot $file ]; then
		echo $file
		get_index $file -60 -45 54 62 > $series
	fi
	if [ ${f%_5m} != $f -o ${f%_sal700} != $f -o ${f%_sal2000} != $f ]; then
		for i in 1 2 3 4 5
		do
			series=${f}_mask$i.dat
			if [ ! -s $series -o $series -ot $file ]; then
				echo $file
				case $i in
					1) get_index $file -30 -20 65 70 > $series;;
					2) get_index $file -55 -45 50 60 > $series;;
					3) get_index $file -45 -25 45 52.5 > $series;;
					4) get_index $file -20 -10 52.5 57.5 > $series;;
					5) get_index $file -20  20 62.5 70 > $series;;
					*) echo "$0: error: i should be in 1,2,3,4,5; not $i"; exit -1;;
				esac
			fi
		done
	fi
done
