#!/bin/sh
yyyy=`date -d '1 month ago' +%Y`
mon=`date -d '1 month ago' +%m`
yy=`date -d '1 month ago' +%y`
doy=`date -d $yyyy-$mon-01 +%j`
yymmdd=`date -d $yyyy-$mon-01 +%y%m%d`
echo $yr

dataset=3A12
echo $dataset
urls="ftp://disc2.nascom.nasa.gov/data/s4pa//TRMM_L3/TRMM_$dataset/$yyyy/$doy/$dataset.$yymmdd.6.HDF.Z"

echo Checking $urls
for url in $urls
do
  file=`basename $url .Z`
  if [ ! -f $file ]
  then
    wget $url
    gunzip $file.Z
  fi
done

# Stub out hdf2netcdf
echo ./hdf2netcdf.sh 3A12*.HDF

dataset=3B43
echo $dataset
# N.B.:  3B43 version is 6A, not 6, and not compressed
urls="ftp://disc2.nascom.nasa.gov/data/s4pa//TRMM_L3/TRMM_$dataset/$yyyy/$doy/$dataset.$yymmdd.6A.HDF"
echo Checking $urls
for url in $urls
do
  file=`basename $url`
  if [ ! -f $file ]
  then
    wget $url
  fi
done

echo ./hdf2netcdf.sh 3B43*.HDF
