#!/bin/sh
# SPEI drought indices fields from CSIC (http://sac.csic.es/spei/index.html)
###base=http://digital.csic.es/bitstream/10261/48169
base=https://digital.csic.es/bitstream/10261/104742
for month in 01 03 04 06 08 12 16 24 36 48
do
	file=SPEI_$month.nc
	case $month in
		01) dir=3;;
		03) dir=5;;
		04) dir=6;;
		06) dir=8;;
		08) dir=10;;
		12) dir=14;;
		16) dir=18;;
		24) dir=26;;
		36) dir=39;;
		48) dir=51;;
		*) echo "$0: error: unknown month $month"; exit -1;;
	esac
	###dir=${month#0}
	wget -N $base/$dir/$file
# 	if [ ! -s $file -o $file.gz -nt $file ]; then
# 		gunzip -c $file.gz > $file
# 	fi
	describefield $file
done
$HOME/NINO/copyfiles.sh SPEI_??.nc
