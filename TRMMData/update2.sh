#!/bin/sh
#yr=`date -d '1 month ago' +%Y`
yr=2009
echo $yr

echo 3A12
#curl http://disc.sci.gsfc.nasa.gov/daac-bin/whom/mk_page_cgi.pl?PATH=datapool/TRMM_DP/01_Data_Products/02_Gridded/01_Monthly_Tmi_Prod_3A_12/$yr > page_3a12.html
#urls=`fgrep 3A12. page_3a12.html | fgrep -v xml | sed -e 's/^.*href="//' -e 's/".*$//'`

# Do search in two steps to avoid complexity with escaping '&' and '()'
mirador="http://mirador.gsfc.nasa.gov/cgi-bin/mirador/granlist.pl?maxgranules=40&pointLocation=-180,-60,180,60&startTime=2009-01-01T00:00:00Z&endTime=2009-03-01T00:00:00Z&format=rss&dataSet=TRMM_3A12.006"
curl $mirador > page_3a12.rss 
urls=`fgrep '<link>ftp' page_3a12.rss | sed -e 's/.*<link>//' -e 's#</link>.*$##'`

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

echo 3B43
#curl http://disc.sci.gsfc.nasa.gov/daac-bin/whom/mk_page_cgi.pl?PATH=datapool/TRMM_DP/01_Data_Products/02_Gridded/07_Monthly_Other_Data_Source_3B_43/$yr > page_3b43.html
mirador="http://mirador.gsfc.nasa.gov/cgi-bin/mirador/granlist.pl?maxgranules=40&pointLocation=-180,-60,180,60&startTime=2009-01-01T00:00:00Z&endTime=2009-03-01T00:00:00Z&format=rss&dataSet=TRMM_3B43.006"
curl $mirador > page_3b43.rss
urls=`fgrep '<link>ftp' page_3b43.rss | sed -e 's/.*<link>//' -e 's#</link>.*$##'`
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


