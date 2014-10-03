#!/bin/sh
for file in HadISST1_SST_1870-1900.txt HadISST1_SST_1901-1930.txt HadISST1_SST_1931-1960.txt HadISST1_SST_1961-1990.txt HadISST1_SST_1991-2003.txt
do
  cp $file.gz $file.gz.old
  wget -N --header="accept-encoding: gzip" http://www.metoffice.gov.uk/hadobs/hadisst/data/$file.gz
  cmp $file.gz $file.gz.old
  if [ $? != 0 ]; then
      c=`file $file.gz | fgrep -c ASCII`
      if [ $c = 0 ]; then
	  gunzip -c $file.gz > $file
      else
	  cp $file.gz $file
      fi
  fi
  rm $file.gz.old
done 

yr=2004
now=`date -d "1 month ago" "+%Y"`
while [ $yr -le $now ]
do
  file=HadISST1_SST_$yr.txt
  cp $file.gz $file.gz.old
  wget -N --header="accept-encoding: gzip" http://www.metoffice.gov.uk/hadobs/hadisst/data/$file.gz
  cmp $file.gz $file.gz.old
  if [ $? != 0 ]; then
      c=`file $file.gz | fgrep -c ASCII`
      if [ $c = 0 ]; then
	  gunzip -c $file.gz > $file
      else
	  cp $file.gz $file
      fi
  fi
  rm $file.gz.old
  yr=$((yr + 1))
done

make hadisst2grads
./hadisst2grads
$HOME/NINO/copyfilesall.sh hadisst1.ctl hadisst1.grd

cp HadISST_ice.nc HadISST_ice.nc.old
wget -N --header="accept-encoding: gzip" http://www.metoffice.gov.uk/hadobs/hadisst/data/HadISST_ice.nc.gz
c=`file  HadISST_ice.nc.gz | fgrep -c zip`
if [ $c = 1 ]; then
    gunzip -c HadISST_ice.nc.gz > HadISST_ice.nc
else
    cp HadISST_ice.nc.gz HadISST_ice.nc
fi
$HOME/NINO/copyfiles.sh HadISST_ice.nc

./makenino.sh
./make_iod.sh
./make_siod.sh
$HOME/NINO/copyfilesall.sh hadisst1_*.dat
