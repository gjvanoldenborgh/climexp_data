#!/bin/sh
wget="wget --no-check-certificate -q -N"
cdo="cdo -r -f nc4 -z zip"
base=http://hadobs.metoffice.gov.uk/hadisst/data/

for var in sst ice; do
    case $var in
        sst) ncvar=sst;;
        ice) ncvar=sic;;
    esac
    echo "$wget $base/HadISST_$var.nc.gz"
    $wget $base/HadISST_$var.nc.gz
    gunzip -c HadISST_$var.nc.gz > HadISST1_${var}_tmp.nc
    $cdo -selvar,$ncvar -setctomiss,-1000. HadISST1_${var}_tmp.nc HadISST_$var.nc
    file=HadISST_$var.nc
    . $HOME/climexp/add_climexp_url_field.cgi
    $HOME/NINO/copyfiles.sh HadISST_$var.nc
done
rm HadISST1_${var}_tmp.nc

./makenino.sh
./make_iod.sh
./make_siod.sh
$HOME/NINO/copyfilesall.sh hadisst1_*.dat
