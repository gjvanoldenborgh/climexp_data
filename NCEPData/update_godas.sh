#!/bin/sh
base=http://cfs.ncep.noaa.gov/cfs/godas/monthly
yr=1980
mo=1
exist=true
while [ $exist = true ]
do
  if [ $mo -lt 10 ]; then
    mm=0$mo
  else
    mm=$mo
  fi
  wget -N $base/godas.M.$yr$mm.grb
  if [ ! -s godas.M.$yr$mm.grb ]; then
    exist=false
  else
    wget -N $base/godas.M.$yr$mm.grb.inv
    mo=$((mo+1))
    if [ $mo = 13 ]; then
      mo=1
      yr=$((yr+1))
    fi
  fi
done
for grid in t u w
do
  wget -N $base/godas_monthly_${grid}grid.ctl
  wget -N $base/godas.monthly.${grid}grid.grb.idx
done
