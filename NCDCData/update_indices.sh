#!/bin/sh

base=ftp://ftp.ncdc.noaa.gov/pub/data/anomalies/

# to speed up the script, NCDC delays every login
wget -q -N $base/monthly\*dat

files=""
for region in gl nh sh
do
  case $region in
  gl) regionname=global;;
  nh) regionname="Northern Hemisphere";;
  sh) regionname="Southern Hemisphere";;
  esac
  for area in land ocean land_ocean
  do
    case $region in
    gl) file=monthly.${area}.90S.90N.df_1901-2000mean.dat;;
    nh) file=monthly.${area}.00N.90N.df_1901-2000mean.dat;;
    sh) file=monthly.${area}.90S.00N.df_1901-2000mean.dat;;
    esac
###    cp $file $file.old
###    wget -N $base$file
    if [ $area = land_ocean ]; then
      myfile=ncdc_${region}.dat
    else
      myfile=ncdc_${region}_${area}.dat
    fi
    cat > $myfile <<EOF
# $regionname $area mean temperature anomalies from <a href="http://lwf.ncdc.noaa.gov/oa/climate/research/anomalies/anomalies.html">NCDC</a>
# Ta [K] surface temperature
EOF
    cat $file >> $myfile
    yrfile=`basename $myfile .dat`_yr.dat
    daily2longer $myfile 1 mean > $yrfile
    files="$files $myfile $yrfile"
    plotdat $yrfile > `basename $yrfile .dat`.txt
  done
done
$HOME/NINO/copyfilesall.sh $files

