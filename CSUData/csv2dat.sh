#!/bin/sh
for time in annual monthly
do
  for var in ace ntc
  do
    case $var in
    ace) longname="Accumulated Cyclone Energy Index";;
    ntc) longname="Net Tropical Cyclone Activity";;
    esac

    infile=`ls -t ${time}_atlantic_${var}_*.csv | head -1`
    file=atlantic_${time}_${var}.dat

    cat > $file << EOF 
# Atlantic basin $time hurricane statistics
# $var [1] $longname
# from Phil Klotzbach, CSU
EOF
    cat $infile | tr ',' ' ' >> $file
    $HOME/NINO/copyfiles.sh $file
  done
done
