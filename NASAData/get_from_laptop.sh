#!/bin/sh
for ext in .dat .nc
do
    rsync -avt ${gatotkaca}climexp/NASAData/giss_\*$ext .
    $HOME/NINO/copyfilesall.sh giss_*$ext
done
rsync -avt ${gatotkaca}climexp/NASAData/saod_*.dat .
$HOME/NINO/copyfilesall.sh saod_*.dat
