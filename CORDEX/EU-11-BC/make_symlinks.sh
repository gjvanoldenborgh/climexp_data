#!/bin/bash
scenarios="rcp45 rcp45"
vars="prAdjust tasAdjust"
for $scenario in $scenarios; do
    for $var in $vars; do
        i=0
        ii=00
        for file in ${var}_*_${scenario}_*_19710101-21001231_latlon.nc; do
            if [ ! -s $file ]; then
                echo "$0: error: cannot find $file"
                exit -1
            fi
            link=${var}_day_eu11bc_${scenario}_${ii}.nc
            ln -s $file $link
            ((i++))
            ii=`printf %02i $i`
        done
    done
done