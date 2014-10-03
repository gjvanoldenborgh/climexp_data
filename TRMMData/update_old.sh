#!/bin/sh
yr=`date -d '1 month ago' +%Y`
echo $yr

echo 3A12
curl http://disc.sci.gsfc.nasa.gov/daac-bin/whom/mk_page_cgi.pl?PATH=datapool/TRMM_DP/01_Data_Products/02_Gridded/01_Monthly_Tmi_Prod_3A_12/$yr > page_3a12.html
urls=`fgrep 3A12. page_3a12.html | fgrep -v xml | sed -e 's/^.*href="//' -e 's/".*$//'`
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

./hdf2netcdf.sh 3A12*.HDF

echo 3B43
curl http://disc.sci.gsfc.nasa.gov/daac-bin/whom/mk_page_cgi.pl?PATH=datapool/TRMM_DP/01_Data_Products/02_Gridded/07_Monthly_Other_Data_Source_3B_43/$yr > page_3b43.html
urls=`fgrep 3B43. page_3b43.html | fgrep -v xml | sed -e 's/^.*href="//' -e 's/".*$//'`
echo Checking $urls
for url in $urls
do
  file=`basename $url`
  if [ ! -f $file ]
  then
    wget $url
  fi
done

./hdf2netcdf.sh 3B43*.HDF


