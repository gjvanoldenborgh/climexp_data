#!/bin/sh

# RSS data

base=ftp://ftp.remss.com/msu/data/netcdf
version=v3_3
for layer in tlt # tmt tts tls
do
  for anom in _anom ""
  do
    wget -q -N $base/rss_tb${anom}_maps_ch_${layer}_${version}.nc
    ncks -O -v brightness_temperature rss_tb${anom}_maps_ch_${layer}_${version}.nc rss_$layer$anom.nc
    ncrename -v brightness_temperature,$layer -v months,time -d months,time rss_$layer$anom.nc
    ncatted -a units,longitude,m,c,"degrees_east" -a units,latitude,m,c,"degrees_north" rss_$layer$anom.nc
    $HOME/NINO/copyfiles.sh rss_$layer$anom.nc
  done
done
get_index rss_tlt_anom.nc 0 360 -90 90 > rss_tlt_gl.dat
get_index rss_tlt_anom.nc 0 360 -90  0 > rss_tlt_sh.dat
get_index rss_tlt_anom.nc 0 360   0 90 > rss_tlt_nh.dat
$HOME/NINO/copyfilesall.sh rss_tlt_??.dat

exit

yr=`date +%Y`
mo=`date +%m`
if [ -f downloaded_$yr$mo ]; then
  echo "Already downloaded TMI this month"
  exit
fi

base=ftp://ftp.discover-earth.org/sst/daily

# TMI only

echo checking old data
wget -q -N $base/tmi/tmi.fusion.1998.???.v0?.gz
wget -q -N $base/tmi/tmi.fusion.1999.???.v0?.gz
wget -q -N $base/tmi/tmi.fusion.2000.???.v0?.gz
wget -q -N $base/tmi/tmi.fusion.2001.???.v0?.gz
wget -q -N $base/tmi/tmi.fusion.2002.???.v0?.gz

# TMI + AMSRE combined

echo retrieving new data
wget -q -N $base/tmi_amsre/tmi_amsre.fusion.*.v02.gz
# it sometimes fails, try again
wget -q -N $base/tmi_amsre/tmi_amsre.fusion.*.v02.gz
# it sometimes fails, try again
wget -q -N $base/tmi_amsre/tmi_amsre.fusion.*.v02.gz

#make dat2dat
echo converting to GrADS
./dat2dat

echo copying to climexp
$HOME/NINO/copyfiles.sh ssmi_sst.ctl ssmi_sst.grd

date > downloaded_$yr$mo
