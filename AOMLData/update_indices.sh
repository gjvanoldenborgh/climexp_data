#!/bin/sh
yrnow=`date +%Y`
yr=1981
while [ $yr -lt $yrnow ]
do
  yr=$((yr+1))
  wget -q -N http://www.aoml.noaa.gov/phod/floridacurrent/FC_cable_transport_$yr.dat
done
make cable2dat
./cable2dat > FC_daily.dat
daily2longer FC_daily.dat 12 mean | sed -e 's/FC_daily/FC_monthly/' > FC_monthly.dat
$HOME/NINO/copyfiles.sh FC_*.dat
