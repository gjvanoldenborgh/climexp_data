#!/bin/bash
if [ -n "$MEI_UPDATED_AGAIN" ]; then
cp table.html table.html.old
url=https://www.esrl.noaa.gov/psd/enso/mei/table.html
wget -N $url
cat > mei.dat <<EOF
# MEI [1] Multivariate ENSO Index
# shifted by 0.5 month, i.e., the Jan value represents the Dec/Jan MEI index.
# from <a href="https://www.esrl.noaa.gov/psd/enso/mei/">ESRL</a>
# insitution :: NOAA/ESRL
# author :: Klaus Wolters
# link :: https://www.esrl.noaa.gov/psd/enso/mei/
# source :: $url
# history :: retrieved from NOAA/ESRL on `date`
EOF
egrep '^[12][0-9]' table.html >> mei.dat
lastline=`tail -1 mei.dat`
ndef=`echo $lastline | wc -w`
ndef=$((ndef - 1))
nundef=$((12 - ndef))
undef=""
while [ $nundef -gt 0 ]; do
  undef="$undef -999.9"
  nundef=$((nundef - 1))
done
sed -e "s/$lastline/$lastline $undef/" mei.dat > aap.dat
mv aap.dat mei.dat
$HOME/NINO/copyfiles.sh mei.dat

fi # MEI

cp olr.mon.mean.nc olr.mon.mean.nc.old
wget -N ftp://ftp.cdc.noaa.gov/Datasets/interp_OLR/olr.mon.mean.nc
describefield olr.mon.mean.nc
$HOME/NINO/copyfiles.sh olr.mon.mean.nc
