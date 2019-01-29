#!/bin/sh
yr=`date +%Y -d now`
mo=`date +%m -d now`
yr1=`date +%Y -d '1 month ago'`
mo1=`date +%m -d '1 month ago'`
base=https://climate.copernicus.eu/sites/default/files/${yr}-${mo}/
file=ts_1month_anomaly_Global_ei_2T_${yr1}${mo1}.csv
wget --no-check-certificate -N $base/$file
for ext in gl eu; do
    case $ext in
        gl) region="the world";col=2;;
        eu) region="Europe (land area in 35-80N;20W-40E)";col=3;;
        *) echo "$0: error:  ext=$ext"; exit -1;;
    esac
    outfile=erai_t2m_$ext.dat
    cat > $outfile <<EOF
# t2m [K} surface air temperature anomalies relative to 1981-2010
# from the ERA-interim reanalysis (first-odrer corrected for the inhomogeneity in 2001)
# averaged over $region
# institution :: Copernicus Climate Change Service
# contact :: Adrian.Simmons@ecmwf.int
# source_url :: $base/$file
# source :: https://climate.copernicus.eu/node/201
# history :: downloaded and converted by $USER at `date`
EOF
    egrep '^[12]' $file | cut -f 1,$col -d ',' | tr ',' ' ' >> $outfile
done
$HOME/NINO/copyfilesall.sh erai_t2m_??.dat