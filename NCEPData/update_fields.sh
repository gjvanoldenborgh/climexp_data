#!/bin/bash
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
set t 49 $n
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
ncatted -h -a title,global,a,c,"NCEP CAMSOPI ANALYSIS $version" \
        -a long_name,prcp,a,c,"blended precipitation" \
        -a units,prcp,a,c,"mm/dy" camsopi.nc
ncatted -h -a title,global,a,c,"NCEP CAMSOPI ANALYSIS $version" \
        -a long_name,perc,a,c,"anomalies expressed as % of gamma" \
        -a units,perc,a,c,"%" camsopi_perc.nc
for file in camsopi.nc camsopi_perc.nc; do
    ncatted -h -a institution,global,o,c,"NOAA/CPC" \
            -a version,global,c,c,"$version" \
            -a source_url,global,c,c,"http://www.cpc.ncep.noaa.gov/products/global_precip/html/wpage.cams_opi.html" \
            -a reference,global,c,c,"Janowiak, J. E. and P. Xie, 1999: CAMS_OPI: a global satellite-raingauge merged product for real-time precipitation monitoring applications. J. Climate, 12, 3335-3342." \
                $file
    . $HOME/climexp/add_climexp_url_field.cgi
done
$HOME/NINO/copyfiles.sh camsopi.nc camsopi_perc.nc

# OIv2 SST
make oiv22grads
./oiv22grads
grads2nc sstoi_v2.ctl sstoi_v2.nc
grads2nc iceoi_v2.ctl iceoi_v2.nc
for file in sstoi_v2.nc iceoi_v2.nc; do
    ncatted -h -a institution,global,o,c,"NOAA/NCEP" \
            -a source_url,global,c,c,"http://www.emc.ncep.noaa.gov/research/cmb/sst_analysis/" \
            -a contact,global,c,c,"Diane.Stokes@noaa.gov" \
            -a reference,global,c,c,"Reynolds, R. W., N. A. Rayner, T. M. Smith, D. C. Stokes and W. Wang, 2002: An improved in situ and satellite SST analysis for climate. J. Climate, 15, 1609-1625. https://doi.org/10.1175/1520-0442(2002)015%3C1609:AIISAS%3E2.0.CO;2" \
                $file
    . $HOME/climexp/add_climexp_url_field.cgi
done
$HOME/NINO/copyfilesall.sh sstoi_v2.nc iceoi_v2.nc

base=ftp://ftp.cpc.ncep.noaa.gov/precip/cmap/monthly
wget -N -q $base/\*.txt.gz
for file in cmap_mon_*.txt.gz; do
    if [ ${file%.gz} -ot $file ]; then
        gunzip -c $file > ${file%.gz}
    fi
done
file=`ls -t cmap_mon_*.txt.gz | head -1`
make cmap2dat
./cmap2dat $file
grads2nc cmap.ctl cmap.nc
file=cmap.nc
ncatted -h -a institution,global,o,c,"NOAA/CPC" \
        -a source_url,global,c,c,"http://www.cpc.ncep.noaa.gov/products/global_precip/html/wpage.cmap.html" \
        -a reference,global,c,c,"Xie P., and P. A. Arkin, 1996: Global precipitation: a 17-year monthly analysis based on gauge observations, satellite estimates, and numerical model outputs. Bull. Amer. Meteor. Soc., 78, 2539-2558." \
            $file
. $HOME/climexp/add_climexp_url_field.cgi
$HOME/NINO/copyfiles.sh cmap.nc
