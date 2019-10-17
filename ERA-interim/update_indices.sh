#!/bin/sh
echo "These indices are no longer updated by Copernicus"
exit -1

yr=`date +%Y -d now`
mo=`date +%m -d now`
yr1=`date +%Y -d '1 month ago'`
mo1=`date +%m -d '1 month ago'`
yr2=`date +%Y -d '2 months ago'`
mo2=`date +%m -d '2 months ago'`
base=https://climate.copernicus.eu/sites/default/files/${yr}-${mo}/
file=ts_1month_anomaly_Global_ea_2T_${yr1}${mo1}.csv
wget --no-check-certificate -N $base/$file
if [ ! -s $file ]; then
    file1=$file
    base=https://climate.copernicus.eu/sites/default/files/${yr1}-${mo1}/
    file=ts_1month_anomaly_Global_ea_2T_${yr2}${mo2}.csv
    wget --no-check-certificate -N $base/$file
    if [ ! -s $file ]; then
        echo "$0: error: cannot find $file1 or $file"
        exit -1
    fi
fi
for ext in gl eu; do
    case $ext in
        gl) region="the world";col=2;;
        eu) region="Europe (land area in 35-80N;20W-40E)";col=3;;
        *) echo "$0: error:  ext=$ext"; exit -1;;
    esac
    outfile=erai_t2m_$ext.dat
    cat > $outfile <<EOF
# t2m [K} surface air temperature anomalies relative to 1981-2010
# from the ERA-interim reanalysis (first-order corrected for the inhomogeneity in 2001)
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
