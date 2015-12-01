#!/bin/sh
wget -N http://www.jamstec.go.jp/frcgc/research/d1/iod/DATA/dmi.monthly.txt
for region in seio wio siod
do
    case $region in
        seio) col=5;name="East Indian Ocean";;
        wio) col=6;name="West Indian Ocean";;
        siod) col=7;name="DMI (WIO-SEIO)";;
        *) echo "$0: error bcguwyoageylucw"; exit -1;;
    esac
    echo "# $region [Celsius] $name SST anomalies" > $region.dat
    echo "# from <a href=http://www.jamstec.go.jp/frcgc/research/d1/iod/e/iod/about_iod.html>JAMSTEC</a>" >> $region.dat
    tail -n +2 dmi.monthly.txt | tr ":" " " | cut -d " " -f 1,2,$col >> $region.dat
done
$HOME/NINO/copyfiles.sh *.dat