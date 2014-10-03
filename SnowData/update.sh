#!/bin/sh
yrnow=`date +"%Y"`
yrthen=$(($yrnow - 1))
wget -N ftp://ftp.cpc.ncep.noaa.gov/wd52dg/snow/wkly_89x89/wk\*
###wget -N ftp://ftp.cpc.ncep.noaa.gov/wd52dg/snow/snw_2x2/grd\*
wget -N ftp://ftp.cpc.ncep.noaa.gov/wd52dg/snow/yrly_date/\*

for file in convert_89to2 week2month
do
  make $file
  ./$file
done

$HOME/NINO/copyfiles.sh nhsnow.ctl nhsnow.grd
