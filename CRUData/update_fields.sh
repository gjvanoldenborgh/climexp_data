#!/bin/sh
#
# CRUTEM, HadCRUT
#
version=4.4.0.0
for field in CRUTEM.${version}.anomalies CRUTEM.${version}.variance_adjusted
do
  file=$field.nc.gz
  cp $file $file.old
  wget -N --header="accept-encoding: gzip" http://www.metoffice.gov.uk/hadobs/crutem4/data/gridded_fields/$file
  if cmp $file $file.old
  then
    echo "no change"
  else
    rm $file.old
    gunzip -c $file > $field.nc
    ncks -O -v temperature_anomaly $field.nc aap.nc
    mv aap.nc $field.nc
    # 1850-01-00 is not really a valid date
    ###ncatted -a axis,unspecified,a,c,"z" -a axis,latitude,a,c,"y" -a axis,longitude,a,c,"x" -a units,t,m,c,"days since 1850-01-01 00:00:00" $field.nc
    $HOME/NINO/copyfiles.sh $field.nc
  fi
done

###make jones2dat
for field in CRUTEM3 CRUTEM3v CRUTEM3_nobs
do
  file=$field.nc
  cp $file $file.old
  wget -N http://www.metoffice.gov.uk/hadobs/crutem3/data/$file
  if cmp $file $file.old
  then
    echo "no change"
  else
    rm $file.old
    myfile=`basename $file .nc`_ce.nc
    ncatted -O -a axis,unspecified,a,c,"z" -a axis,latitude,a,c,"y" -a axis,longitude,a,c,"x" $file $myfile
    $HOME/NINO/copyfiles.sh $myfile
  fi
done
./makeiozm.sh
$HOME/NINO/copyfiles.sh seio_hadsst2.dat wio_hadsst2.dat

wget -N http://www.metoffice.gov.uk/hadobs/hadcruh/data/CRU_blendnewjul08_q_7303cf.nc
$HOME/NINO/copyfiles.sh CRU_blendnewjul08_q_7303cf.nc
wget -N http://www.metoffice.gov.uk/hadobs/hadcruh/data/CRU_blendnewjul08_RH_7303cf.nc
$HOME/NINO/copyfiles.sh CRU_blendnewjul08_RH_7303cf.nc

exit
. ./update_cru_ts.sh
