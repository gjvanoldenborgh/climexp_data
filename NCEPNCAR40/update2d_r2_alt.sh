#!/bin/bash
yr=`date -d "last month" "+%Y"`
yr1=$((yr-1))
mm1=`date -d "last month" "+%m" | sed -e 's/^0//'`
n=$(( (yr-1948)*12 ))
base=ftp://ftp.cdc.noaa.gov/Datasets/ncep.reanalysis2.dailyavgs/gaussian_grid

###  mv air.2m.gauss.$yr.nc air.2m.gauss.$yr.nc.old
###  wget $base/air.2m.gauss.$yr.nc

rm air.2m.mon.$yr.???
daily2longerfield air.2m.gauss.$yr.nc 12 mean standardunits air.2m.mon.$yr.ctl
cat nt2m_$yr1.grd air.2m.mon.$yr.dat > nt2m.grd
sed -e "s/ $n / $((n+mm1)) /" -e "s/nt2m.*.grd/nt2m.grd/" nt2m_$yr1.ctl > nt2m.ctl

$HOME/NINO/copyfiles.sh  nt2m.???

mv prate.sfc.gauss.2008.nc prate.sfc.gauss.2008.nc.old
wget $base/prate.sfc.gauss.2008.nc

rm prate.sfc.mon.$yr.???
daily2longerfield prate.sfc.gauss.$yr.nc 12 mean prate.sfc.mon.$yr.ctl
cat nprcp_$yr1.grd prate.sfc.mon.$yr.dat > nprcp.grd
sed -e "s/ $n / $((n+mm1)) /" -e "s/nprcp.*.grd/nprcp.grd/" nprcp_$yr1.ctl > nprcp.ctl

$HOME/NINO/copyfiles.sh  nprcp.???

