#!/bin/bash
# download GPCC v4
base=ftp://ftp.dwd.de/pub/data/gpcc/full_data/
yr=1901
while [ $yr -lt 2011 ]
do
  if [ $yr = 2001 ]
  then
    yr1=2007
  else
    yr1=$((yr+9))
  fi
  for res in 05 10 25
  do
    file=gpcc_full_data_archive_v004_${res}_degree_${yr}_${yr1}.zip
    wget -N $base/$file
  done
  yr=$((yr+10))
done

make v4tograds
for res in 05 10 25
do
  ./v4tograds $res
  if [ $res = 05 ]
  then
    gzip  gpcc_V4_${res}.grd  gpcc_V4_${res}_n1.grd
  fi
  $HOME/NINO/copyfiles.sh gpcc_V4_${res}.ctl gpcc_V4_${res}.grd*
  $HOME/NINO/copyfiles.sh gpcc_V4_${res}_n1.ctl gpcc_V4_${res}_n1.grd*
done
