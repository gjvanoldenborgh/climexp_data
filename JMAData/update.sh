#!/bin/bash
yr=1950
yrnow=`date +%Y`

base=http://www.data.jma.go.jp/gmd/kaiyou/data/english/ohc/grid
while [ $yr -lt $yrnow ]
do
    if [ $((yr+9)) -ge $yrnow ]; then
        file=ohc_${yr}_last.ZIP
    else
        file=ohc_${yr}_$((yr+9)).ZIP
    fi
    wget -N -q $base/$file
    unzip -o $file
    yr=$((yr+10))
done

make dat2grads
./dat2grads
grads2nc heat700_jma.ctl heat700_jma.nc
$HOME/NINO/copyfiles.sh heat700_jma.nc
