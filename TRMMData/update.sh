#!/bin/sh
for dataset in 3A12 3B43
do
  echo $dataset

  lag=0
  urls=""
  while [ $lag -lt 12 ]; do
      lag=$((lag+1))
      yyyy=`date -d "$lag months ago" +%Y`
      mon=`date -d "$lag months ago" +%m`
      yy=`date -d "$lag months ago" +%y`
      doy=`date -d $yyyy-$mon-01 +%j`
      yymmdd=`date -d $yyyy-$mon-01 +%Y%m%d`
      if [ $dataset = 3A12 ]
          then
          urls="$urls ftp://disc2.nascom.nasa.gov/ftp/data/s4pa/TRMM_L3/TRMM_$dataset/$yyyy/$doy/$dataset.$yymmdd.7.HDF.Z"
      else
          # N.B.:  3B43 version is 6A, not 6, and not compressed
          urls="$urls http://disc2.nascom.nasa.gov/s4pa/TRMM_L3/TRMM_$dataset/$yyyy/$doy/$dataset.$yymmdd.6A.HDF"
      fi
  done
  for url in $urls
  do
    echo Checking $url
    wget -q -N --timeout=10 $url
    file=`basename $url .Z`
    if [ -f $file.Z -a ! -f $file -o $file -ot $file.Z ]
    then
        gunzip -c $file.Z > $file
    fi
    oldfile=`echo $file | sed -e 's/\.7\./.6./' -e 's/\.20/./'`
    if [ -s $file -a -s $oldfile -a $file -nt $oldfile ]; then
      rm $oldfile
    fi
    oldfile=`echo $file | sed -e 's/\.7\./.6A./' -e 's/\.20/./'`
    if [ -s $file -a -s $oldfile -a $file -nt $oldfile ]; then
      rm $oldfile
    fi
  done

  # convert to netcdf
  if [ $dataset = 3B43 ]; then
      ./hdf2netcdf_v6.sh ${dataset}.*.6.HDF ${dataset}.*.6A.HDF
  else
      ./hdf2netcdf.sh ${dataset}.*.HDF
  fi
done # dataset
