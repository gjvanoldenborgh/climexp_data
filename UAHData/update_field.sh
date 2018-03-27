#!/bin/sh
yr=1979
version="6.0"
myversion="60"
base=http://www.atmos.uah.edu/public/msu/v6.0/tlt/
yrnow=`date -d "last month" +"%Y"`
while [ $yr -le $yrnow ]
do
  file=tltmonamg.${yr}_$version
  wget -q -N $base$file
  size=`wc -c $file | awk '{print $1}'`
  if [ -n "$size" -a ${size:-0} -lt 500 ]
  then
    echo "$0: error retrieving $base$file"
    rm $file
    yr=3000
  fi
  yr=$(($yr + 1))
done

make msu2grads
./msu2grads $version
grads2nc tlt.ctl tlt.nc
mv tlt.nc tlt_$myversion.nc
file=tlt_$myversion.nc
ncatted -h -a institution,global,o,c,"Earth System Science Center, the University of Alabama in Huntsville" \
        -a source_url,global,c,c,"https://www.nsstc.uah.edu/climate/" \
        -a contact,global,c,c,"gentry@nsstc.uah.edu" \
        -a version,global,c,c,"$version" \
            $file
. $HOME/climexp/add_climexp_url_field.cgi

cp tlt_$myversion.nc tlt.nc

get_index tlt.nc 0 360 -90 90 > tlt_gl.dat
get_index tlt.nc 0 360 -90 0 > tlt_sh.dat
get_index tlt.nc 0 360 0 90 > tlt_nh.dat
get_index tlt.nc 0 360 -90 90 lsmask lsmask_25_180.nc 5lan > tlt_land.dat
get_index tlt.nc 0 360 -90 90 lsmask lsmask_25_180.nc 5sea > tlt_sea.dat
###. ./update_indices.sh

$HOME/NINO/copyfiles.sh tlt*.nc tlt_??.dat tlt_land.dat tlt_sea.dat

exit 

# old versions
yr=1979
for version in "5.6" "5.5"
do
base=http://www.atmos.uah.edu/public/msu/t2lt/
yrnow=`date -d "last month" +"%Y"`
while [ $yr -le $yrnow ]
do
  file=tltmonamg.${yr}_$version
  wget -q -N $base$file
  size=`wc -c $file | awk '{print $1}'`
  if [ -n "$size" -a ${size:-0} -lt 500 ]
  then
    echo "$0: error retrieving $base$file"
    rm $file
    file=tltmonamg.${yr}_6.0p
    wget -q -N $base$file
  fi
  size=`wc -c $file | awk '{print $1}'`
  if [ -n "$size" -a ${size:-0} -lt 500 ]
  then
    echo "$0: error retrieving $base$file"
    rm $file
    yr=3000
  fi
  yr=$(($yr + 1))
done

make msu2grads
./msu2grads $version
grads2nc tlt.ctl tlt.nc
case $version in
    5.5) mv tlt.nc tlt_55.nc;;
    5.6) mv tlt.nc tlt_56.nc;;
esac
done # version
