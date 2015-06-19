#!/bin/sh
# CAMSOPI
version=v0208
root=ftp://ftp.cpc.ncep.noaa.gov/precip/data-req/cams_opi_$version
mkdir -p cams_opi_$version
(cd cams_opi_$version; wget -q -N $root/\*)
for file in cams_opi_$version/cams_opi_merged.??????.Z; do
    f=${file%.Z}
    if [ ! -s $f -o $f -ot $file ]; then
        gunzip -c $file > $f
    fi
done
n=`ls cams_opi_$version/cams_opi_merged.?????? | wc -l`
echo "n=$n"
grads -b -l <<EOF
open cams_opi_$version/camsopi.ctl
set x 1 144
set t 1 $n
define prcp=comb
define perc=gam
set sdfwrite camsopi.nc
sdfwrite prcp
clear sdfwrite
set sdfwrite camsopi_perc.nc
sdfwrite perc
clear sdfwrite
quit
EOF
ncatted -a title,global,a,c,"NCEP CAMSOPI ANALYSIS $version" \
        -a long_name,prcp,a,c,"blended precipitation" \
        -a units,prcp,a,c,"mm/dy" camsopi.nc
ncatted -a title,global,a,c,"NCEP CAMSOPI ANALYSIS $version" \
        -a long_name,perc,a,c,"anomalies expressed as % of gamma" \
        -a units,perc,a,c,"%" camsopi_perc.nc
$HOME/NINO/copyfiles.sh camsopi.nc camsopi_perc.nc

# OIv2 SST
make oiv22grads
./oiv22grads
describefield sstoi_v2.ctl
$HOME/NINO/copyfiles.sh sstoi_v2.??? iceoi_v2.???

base=ftp://ftp.cpc.ncep.noaa.gov/precip/cmap/monthly
wget -N -q $base/\*.txt.gz
for file in cmap_mon_*.txt.gz; do
    if [ ${file%.gz} -ot $file ]; then
        gunzip -c $file > ${file%.gz}
    fi
done
n=`ls 
file=`ls -t cmap_mon_*.txt.gz | head -1`
make cmap2dat
./cmap2dat $file
describefield cmap.ctl
$HOME/NINO/copyfiles.sh cmap.???

