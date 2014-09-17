#!/bin/sh
for depth in 700 2000
do

    for b in a i p w
    do
      for season in 1-3 4-6 7-9 10-12
      do
        wget -q -N ftp://ftp.nodc.noaa.gov/pub/data.nodc/woa/DATA_ANALYSIS/3M_HEAT_CONTENT/DATA/basin/3month/h22-${b}0-${depth}m${season}.dat
      done
    done

    ./dat2dat $depth
    $HOME/NINO/copyfilesall.sh heat${depth}_*.dat

    cp HC_0-${depth}-3month.tar.gz HC_0-${depth}-3month.tar.gz.old
    wget -q -N ftp://ftp.nodc.noaa.gov/pub/data.nodc/woa/DATA_ANALYSIS/3M_HEAT_CONTENT/DATA/heat_3month/HC_0-${depth}-3month.tar.gz
    cmp HC_0-${depth}-3month.tar.gz HC_0-${depth}-3month.tar.gz.old
    if [ $? != 0 ]; then
      tar zxf HC_0-${depth}-3month.tar.gz
      make dat2grads
      ./dat2grads $depth
      $HOME/NINO/copyfiles.sh heat${depth}.???
    fi
done