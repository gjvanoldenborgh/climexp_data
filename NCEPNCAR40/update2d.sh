#!/bin/sh
if [ -z "$!" ]; then
  force="$1"
fi

for var in slp
do
  file=$var.mon.mean.nc
  if [ -f $file ]; then
    cp $file $file.old
  fi
  wget -q -N ftp://ftp.cdc.noaa.gov/Datasets/ncep.reanalysis.derived/surface/$file
  cmp $file $file.old
  ###if [ $? != 0 -o "$force" = force ]; then
    $HOME/NINO/copyfilesall.sh  $file
  ###fi
done
. ./make_snao.sh
. ./make_nao.sh

export nt=`describefield slp.mon.mean.nc 2>&1 | fgrep months | awk '{print $9}'`
echo "nt = $nt"

for var in air.2m prate.sfc uwnd.10m vwnd.10m uflx.sfc vflx.sfc lhtfl.sfc nswrs.sfc nlwrs.sfc shtfl.sfc soilw.0-10cm skt.sfc
do
  file=$var.mon.mean.nc
  wget -q -N ftp://ftp.cdc.noaa.gov/Datasets/ncep.reanalysis.derived/surface_gauss/$var.mon.mean.nc
  $HOME/NINO/copyfiles.sh  $file
done

for var in ulwrf.ntat
do
  file=$var.mon.mean.nc
  wget -q -N ftp://ftp.cdc.noaa.gov/Datasets/ncep.reanalysis.derived/other_gauss/$var.mon.mean.nc
  $HOME/NINO/copyfiles.sh  $file
done

./make_curl_windstress.sh

# convert from W/m2 to kg/m2/s, simple constant.
cdo divc,2500000. lhtfl.sfc.mon.mean.nc evap.mon.mean.nc
ncrename -v lhtfl,evap evap.mon.mean.nc
ncatted -a units,evap,m,c,"kg/m2/s" -a long_name,evap,m,c,"monthly mean of evaporation (from latent heat flux)" evap.mon.mean.nc
cdo sub prate.sfc.mon.mean.nc evap.mon.mean.nc pme.mon.mean.nc
ncrename -v prate,pme pme.mon.mean.nc
ncatted -a long_name,pme,m,c,"monthly mean of precipitation minus evaporation" pme.mon.mean.nc
$HOME/NINO/copyfiles.sh evap.mon.mean.nc pme.mon.mean.nc

cdo -r -f nc4 -z zip add shtfl.sfc.mon.mean.nc lhtfl.sfc.mon.mean.nc aap.nc
cdo -r -f nc4 -z zip add nswrs.sfc.mon.mean.nc nlwrs.sfc.mon.mean.nc noot.nc
cdo -r -f nc4 -z zip add aap.nc noot.nc netflx.sfc.mon.mean.nc
ncrename -v shtfl,netflux netflx.sfc.mon.mean.nc
ncatted -a long+_name,netflux,m,c,"Monhly mean of Total Net Heat Flux at Surface" \
 -a var_desc,netflux,m,c,"Net Heat Flux" netflx.sfc.mon.mean.nc
rm aap.nc noot.nc

$HOME/NINO/copyfiles.sh netflx.mon.mean.nc ncurl.???

###./make_windspeed.sh
###$HOME/NINO/copyfiles.sh  nwindspeed.???
