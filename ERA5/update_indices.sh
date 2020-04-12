#!/bin/bash

# SAM

if [ era5_msl_extended.nc -nt era5_msl.nc ]; then
    suffix="_extended"
else
    suffix=""
fi
get_index era5_msl$suffix.nc 0 360 -40 -40 nearest > slp40.dat
get_index era5_msl$suffix.nc 0 360 -65 -65 nearest > slp65.dat
normdiff slp40.dat slp65.dat year none | sed -e 's/diff.*$/SAM [1] Southern Annular Mode/' > era5_sam.dat
$HOME/NINO/copyfiles.sh era5_sam.dat

# Copernicus T2m regions

yr=`date +%Y -d now`
mo=`date +%m -d now`
yr1=`date +%Y -d '1 month ago'`
mo1=`date +%m -d '1 month ago'`
yr2=`date +%Y -d '2 months ago'`
mo2=`date +%m -d '2 months ago'`
base=https://climate.copernicus.eu/sites/default/files/${yr}-${mo}/
file=ts_1month_anomaly_Global_ea_2t_${yr1}${mo1}_v01.csv
wget --no-check-certificate -N $base/$file
if [ ! -s $file ]; then
    file1=$file
    base=https://climate.copernicus.eu/sites/default/files/${yr1}-${mo1}/
    file=ts_1month_anomaly_Global_ea_2t_${yr2}${mo2}_v01.csv
    wget --no-check-certificate -N $base/$file
    if [ ! -s $file ]; then
        echo "$0: error: cannot find $file1 or $file"
        exit -1
    fi
fi
for ext in gl eu; do
    case $ext in
        gl) sregion="global";region="the world";col=2;;
        eu) sregion="European land";region="Europe (land area in 34-72N;25W-40E)";col=3;;
        *) echo "$0: error:  ext=$ext"; exit -1;;
    esac
    outfile=era5_t2m_$ext.dat
    cat > $outfile <<EOF
# t2m [K] $sregion T2m anomalies relative to 1981-2010
# from the ERA5 reanalysis, final plus ERA5T for the last months
# averaged over $region
# institution :: Copernicus Climate Change Service
# contact :: Adrian.Simmons@ecmwf.int
# source_url :: $base/$file
# source :: https://climate.copernicus.eu/climate-bulletin-about-data-and-analysis
# history :: downloaded and converted by $USER at `date`
EOF
    egrep '^[12]' $file | cut -f 1,$col -d ',' | tr ',' ' ' >> $outfile
done
$HOME/NINO/copyfilesall.sh era5_t2m_??.dat
