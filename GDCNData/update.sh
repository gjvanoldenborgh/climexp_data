#!/bin/sh
yr=`date +%Y`
mo=`date +%m`
if [ -f downloaded_$yr$mo ]; then
  echo "Already downloaded GHCN-D this month"
  exit
fi
# get data
base=ftp://ftp.ncdc.noaa.gov/pub/data/ghcn/daily/
cp ghcnd-countries.txt ghcnd-countries.txt.old
wget -q -N $base/ghcnd-countries.txt
cp ghcnd-stations.txt ghcnd-stations.txt.old
wget -q -N $base/ghcnd-stations.txt
cp ghcnd_all.tar.gz ghcnd_all.tar.gz.old
wget -q -N $base/ghcnd_all.tar.gz
cmp ghcnd_all.tar.gz ghcnd_all.tar.gz.old
if [ $? = 0 ]; then
  echo ghcnd_all.tar.gz unchanged
  mv ghcnd_all.tar.gz.old ghcnd_all.tar.gz
  exit
fi
cmp ghcnd_all.tar.gz ghcnd_all.tar.gz.old
if [ $? = 0 ]; then
  echo ghcnd_all.tar.gz unchanged
  exit
fi
# check integrity
gzip -t ghcnd_all.tar.gz
if [ $? != 0 ]; then
  echo ghcnd_all.tar.gz corrupt
  mv ghcnd_all.tar.gz.old ghcnd_all.tar.gz
  exit
fi
rm ghcnd_all.tar.gz.old # save space.
rm -rf ghcnd

# extract data
echo "uncompressing and extracting tar file"
tar zxf ghcnd_all.tar.gz

# and compress all files individually
echo "and compressing all data files again"
gzip -r -f ghcnd_all

# swap
mv ghcnd_all ghcnd

# update metadata
echo "update metadata"
make addyears
./addyears > /dev/null

# copy to climexp
echo "copy to climexp"
$HOME/NINO/copyfiles.sh -r ghcnd
$HOME/NINO/copyfiles.sh ghcnd-countries.txt ghcnd-stations.txt ghcnd2.inv.withyears

# make Tmean

date > downloaded_$yr$mo
