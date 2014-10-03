#!/bin/sh
if [ -z "$!" ]; then
  force="$1"
fi

for var in slp
do
  file=$var.mon.mean.nc
  if [ -f $file ]; then
    cp $file $file.old
  fi
  wget -q -N ftp://ftp.cdc.noaa.gov/Datasets/ncep.reanalysis.derived/surface/$file
  cmp $file $file.old
  ###if [ $? != 0 -o "$force" = force ]; then
    $HOME/NINO/copyfilesall.sh  $file
  ###fi
done
. ./make_snao.sh

export nt=`describefield slp.mon.mean.nc 2>&1 | fgrep months | awk '{print $9}'`
echo "nt = $nt"

for var in air.2m prate.sfc uwnd.10m vwnd.10m uflx.sfc vflx.sfc lhtfl.sfc nswrs.sfc nlwrs.sfc shtfl.sfc soilw.0-10cm skt.sfc
do
  file=$var.mon.mean.nc
  if [ -f $file ]; then
    cp $file $file.old
  fi
  wget -q -N ftp://ftp.cdc.noaa.gov/Datasets/ncep.reanalysis.derived/surface_gauss/$var.mon.mean.nc
  cmp $file $file.old
  ###if [ $? != 0 -o "$force" = force ]; then
    $HOME/NINO/copyfiles.sh  $file
  ###fi
done

./make_curl_windstress.sh
$HOME/NINO/copyfiles.sh  ncurl.???

###./make_windspeed.sh
###$HOME/NINO/copyfiles.sh  nwindspeed.???
