#!/bin/sh
for scen in historical historicalNat; do
    for var in pr tasmin tasmax; do
        i=1 # start at 2, the first one is OK
        while [ $i -lt 1000 ]; do
            i=$((i+1))
            ###echo ${var}/${var}_day_HadGEM3-A-N216_${scen}_r1i1p{i}_????????-????????.nc
            for file in ${var}/${var}_day_HadGEM3-A-N216_${scen}_r1i1p${i}_????????-????????.nc; do
                if [ -f $file ]; then # this skips all $i that are too large
                    newfile=`echo $file | sed -e "s/r1i1p${i}/r${i}i1p1/"`
                    mv $file $newfile
                fi
            done
        done
    done
done