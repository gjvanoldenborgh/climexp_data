#!/bin/bash

yr=1993
yrnow=`date "+%Y"`
while [ $yr -lt $yrnow ]
do
  yr=$((yr + 1))
  mo=0
  while [ $mo -lt 12 ]
  do
    mo=$((mo + 1))
    if [ -z "$nomore" -a ! -s $yr$mo.nc ]
    then
      wget ftp://ftp.aoml.noaa.gov/pub/phod/trinanes/GEERTJAN/$yr$mo.nc.gz
      if [ -s $yr$mo.nc.gz ]
      then
        gunzip $yr$mo.nc.gz
      else
        echo "cannot find $yr$mo.nc.gz"
        nomore=true
      fi
    fi
  done
done

ncecat ??????.nc heatpotential.nc
ncrename -v z,heat -d record,time heatpotential.nc
cdo -r settaxis,1994-01-15,0:00,1mon heatpotential.nc aap.nc
