#!/bin/sh
yr=1979
for version in "5.5" "5.6"
do
base=http://vortex.nsstc.uah.edu/public/msu/t2lt/
yrnow=`date -d "last month" +"%Y"`
while [ $yr -le $yrnow ]
do
  file=tltmonamg.${yr}_$version
  wget -q -N $base$file
  size=`wc -c $file | awk '{print $1}'`
  if [ -n "$size" -a $size -lt 500 ]
  then
    rm $file
    file=tltmonamg.${yr}_6.0p
    wget -q -N $base$file
  fi
  size=`wc -c $file | awk '{print $1}'`
  if [ -n "$size" -a $size -lt 500 ]
  then
    rm $file
    yr=3000
  fi
  yr=$(($yr + 1))
done

make msu2grads
./msu2grads
grads2nc tlt.ctl tlt.nc
case $version in
    5.5) mv tlt.nc tlt_55.nc;;
    5.6) cp tlt.nc tlt_56.nc;;
esac
done # version

get_index tlt.nc 0 360 -90 90 > tlt_gl.dat
get_index tlt.nc 0 360 -90 0 > tlt_sh.dat
get_index tlt.nc 0 360 0 90 > tlt_nh.dat
get_index tlt.nc 0 360 -90 90 lsmask lsmask_25_180.nc 5lan > tlt_land.dat
get_index tlt.nc 0 360 -90 90 lsmask lsmask_25_180.nc 5sea > tlt_sea.dat
###. ./update_indices.sh

$HOME/NINO/copyfiles.sh tlt*.nc tlt_??.dat tlt_land.dat tlt_sea.dat
