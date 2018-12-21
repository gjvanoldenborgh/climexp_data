#!/bin/bash
. ./update_wwv.sh

yr=`date +%Y`
mo=`date +%m`
if [ -f downloaded_$yr$mo ]; then
  echo "Already downloaded TAO this month"
  exit
fi

if [ 0 = 1 ]; then
# OHC
wget -N http://oceans.pmel.noaa.gov/Data/OHCA_700.txt
./ohc2dat.sh
$HOME/NINO/copyfiles.sh pmel_ohc700.dat
fi

# 3D temperature

[ ! -d temp ] && mkdir temp
(cd temp; wget -q -N ftp://ftp.pmel.noaa.gov/taodata/temp/\*.tmp)

for ext in '' '-dy'
do

  make temp2dat$ext
  ./temp2dat$ext > temp2dat$ext.log
  nt=`fgrep records temp2dat$ext.log | tail -1 | awk '{print $2}'`
  if [ -z "$nt" ]; then
    echo "ERROR: could not find nt in temp2dat$ext.log"
    exit -1
  fi
  sed -e "s/@NT/$nt/" tao$ext.ctl.in > tao$ext.ctl
  grads2nc tao$ext.ctl tao$ext.nc
  file=tao$ext.nc
  . $HOME/climexp/add_climexp_url_field.cgi
  $HOME/NINO/copyfiles.sh tao$ext.nc

  make getdepth
  ./getdepth 20 $ext > getdepth.log
  sed -e "s/@NT/$nt/" tao_z20$ext.ctl.in > tao_z20$ext.ctl
  grads2nc tao_z20$ext.ctl tao_z20$ext.nc
  file=tao_z20$ext.nc
  . $HOME/climexp/add_climexp_url_field.cgi
  $HOME/NINO/copyfiles.sh tao_z20$ext.nc

done

# surface variables

[ ! -d surface ] && mkdir surface
(cd surface; wget -q -N ftp://ftp.pmel.noaa.gov/taodata/surface/\*.met)

yr=`date "+%Y"`
mo=`date "+%m"`

for ext in '' '-5dy' '-dy'
do

  make surf2dat$ext
  ./surf2dat$ext > surf2dat$ext.log

  nt=`fgrep records surf2dat$ext.log | tail -1 | awk '{print $2}'`
  if [ -z "$nt" ]; then
    echo "ERROR: could not find nt in surf2dat$ext.log"
    exit -1
  fi
  echo "nt = $nt"

  for var in airt rh sst windu windv
  do
    sed -e "s/@NT/$nt/" tao_$var$ext.ctl.in > tao_$var$ext.ctl
    grads2nc tao_$var$ext.ctl tao_$var$ext.nc
    file=tao_$var$ext.nc
    . $HOME/climexp/add_climexp_url_field.cgi
    $HOME/NINO/copyfiles.sh tao_$var$ext.nc
  done

  make u2tau
  rm tao_tau_?$ext.ctl tao_tau_?$ext.dat
  ./u2tau tao_windu$ext.ctl tao_windv$ext.ctl
  for ctlfile in tao_tau_?$ext.ctl; do
    file=${ctlfile%.ctl}.nc
    grads2nc $ctlfile $file
    . $HOME/climexp/add_climexp_url_field.cgi
  done
  $HOME/NINO/copyfiles.sh tao_tau_?$ext.nc

done
date > downloaded_$yr$mo
