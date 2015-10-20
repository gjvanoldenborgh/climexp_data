#!/bin/sh
if [ -z "$1" ]; then
  machine=$gatotkaca
else
  machine="$1"
fi
for ext in .dat .nc
do
    rsync -avt ${machine}climexp/NASAData/giss_\*$ext .
    $HOME/NINO/copyfilesall.sh giss_*$ext
done
rsync -avt ${machine}climexp/NASAData/saod_*.dat .
$HOME/NINO/copyfilesall.sh saod_*.dat
