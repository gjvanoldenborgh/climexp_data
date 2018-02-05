#!/bin/sh
wget -N http://www.jamstec.go.jp/frcgc/research/d1/iod/DATA/dmi.monthly.txt
for region in seio wio dmi
do
    case $region in
        seio) col=6;name="East Indian Ocean";;
        wio) col=5;name="West Indian Ocean";;
        dmi) col=7;name="DMI (WIO-SEIO)";;
        *) echo "$0: error bcguwyoageylucw"; exit -1;;
    esac
    echo "# $region [Celsius] $name SST anomalies" > $region.dat
    echo "# from <a href=http://www.jamstec.go.jp/frcgc/research/d1/iod/e/index.html>JAMSTEC</a>" >> $region.dat
    echo "# history :: retrieved at `date`" >> $region.dat
    tail -n +2 dmi.monthly.txt | tr ":" " " | cut -d " " -f 1,2,$col >> $region.dat
done
$HOME/NINO/copyfiles.sh *.dat