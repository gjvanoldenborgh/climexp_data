#!/bin/bash
wget="wget --no-check-certificate -q -N"

export version=4.6.0.0
base=http://www.metoffice.gov.uk/hadobs/crutem4/data/gridded_fields/
file=CRUTEM.${version}.anomalies.nc
$wget --header="accept-encoding: gzip" $base/$file.gz
gunzip -c $file.gz > $file
ncks -O -v temperature_anomaly $file aap.nc
mv aap.nc $file
. $HOME/climexp/add_climexp_url_field.cgi
$HOME/NINO/copyfilesall.sh $file

base=http://www.metoffice.gov.uk/hadobs/hadcrut4/data/current/gridded_fields
file=HadCRUT.${version}.median_netcdf.zip
$wget --header="accept-encoding: gzip" $base/$file
unzip -o $file
ncks -O -v temperature_anomaly HadCRUT.${version}.median.nc tmp.nc
mv tmp.nc HadCRUT.${version}.median.nc
file=HadCRUT.${version}.median.nc
ncatted -a institution,global,a,c,"Met Office Hadley Centre" \
    -a url,global,a,c,"https://www.metoffice.gov.uk/hadobs/hadcrut4/" $file
. $HOME/climexp/add_climexp_url_field.cgi
$HOME/NINO/copyfilesall.sh HadCRUT.${version}.median.nc

if [ -n "$also_download_ensemble" ]; then
	i1=1
	i2=10
	while $i1 -lt 100 ]; do
		$wget --header="accept-encoding: gzip" http://www.metoffice.gov.uk/hadobs/hadcrut4/data/gridded_fields/hadcrut4_${i1}_to_${i2}_netcdf.zip
		i1=$((i1+10))
		i2=$((i2+10))
	done
fi

for v in 3 4; do
    case $v in
        3) export version=3.1.1.0
            base=https://www.metoffice.gov.uk/hadobs/hadsst$v/data/HadSST.$version/netcdf
            file=HadSST.${version}.median_netcdf.zip;;
        4) export version=4.0.0.0
            base=https://www.metoffice.gov.uk/hadobs/hadsst4/data/netcdf
            file=HadSST.${version}_median.nc;;
        *) echo "error: unknown major version $v"; exit -1;;
    esac
    $wget --header="accept-encoding: gzip" $base/$file
    if [ $v = 3 ]; then
        unzip -o $file
        file=HadSST.${version}.median.nc
    fi
    ncatted -a -h url,global,a,c,"https://www.metoffice.gov.uk/hadobs/hadsst$v/" $file
    . $HOME/climexp/add_climexp_url_field.cgi
    if [ $v = 4 ]; then
        file=HadSST.${version}_total_uncertainty.nc
        $wget $base/$file
        . $HOME/climexp/add_climexp_url_field.cgi
        file=HadSST.${version}_number_of_observations.nc
        $wget $base/$file
        . $HOME/climexp/add_climexp_url_field.cgi
    fi
    $HOME/NINO/copyfilesall.sh HadSST.${version}*.nc

    if [ -n "$also_download_ensemble" ]; then
        i1=1
        i2=10
        while $i1 -lt 100 ]; do
            $wget --header="accept-encoding: gzip" http://www.metoffice.gov.uk/hadobs/hadcrut4/data/gridded_fields/hadcrut4_${i1}_to_${i2}_netcdf.zip
            i1=$((i1+10))
            i2=$((i2+10))
        done
    fi
done

. ./update_hadisst1.sh
. ./update_ipo.sh
. ./update_amo.sh
. ./update_hadslp2.sh

exit

$wget --header="accept-encoding: gzip" http://www.metoffice.gov.uk/hadobs/hadsst3/data/HadSST3_median_netcdf.zip
unzip -o -j HadSST3_median_netcdf.zip
$HOME/NINO/copyfilesall.sh HadSST3_median.nc

$wget --header="accept-encoding: gzip" http://www.metoffice.gov.uk/hadobs/hadsst2/data/HadSST2_SST_1850on.txt.gz
c=`file HadSST2_SST_1850on.txt.gz | fgrep -c ASCII`
if [ $c = 1 ]; then
    cp HadSST2_SST_1850on.txt.gz HadSST2_SST_1850on.txt
else
    gunzip -c HadSST2_SST_1850on.txt.gz > HadSST2_SST_1850on.txt
fi
make hadsst2grads
./hadsst2grads
$HOME/NINO/copyfiles.sh hadsst2.???

./update_hadnmat2.sh
