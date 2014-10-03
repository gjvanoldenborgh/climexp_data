#!/bin/sh
base=ftp://strat50.met.fu-berlin.de/pub/outgoing/_matthes/CMIP5_solardata
wget -N $base/TSI_WLS_ann_1610_2008.txt
wget -N $base/spectra_1610_2000a_21Jan09.txt.gz
wget -N $base/spectra_2000_2008a_6May09.txt.gz
wget -N $base/TSI_WLS_mon_1882_2008.txt
wget -N $base/spectra_1882_2000m_17Dec08.txt.gz
wget -N $base/spectra_2000_2008m_6May09.txt.gz
for file in *.txt.gz
do
    gunzip -c $file > `basename $file .gz`
done

head -2 TSI_WLS_ann_1610_2008.txt | sed -e 's/^/# /' > tsi_wls_ann.dat
echo "# TSI [W/m2] Total Solar Irradiance" >> tsi_wls_ann.dat
tail -n +4 TSI_WLS_ann_1610_2008.txt | sed -e 's/13..\.....  //' >> tsi_wls_ann.dat

head -2 TSI_WLS_mon_1882_2008.txt | sed -e 's/^/# /' > tsi_wls_mon.dat
echo "# TSI [W/m2] Total Solar Irradiance" >> tsi_wls_mon.dat
tail -n +4 TSI_WLS_mon_1882_2008.txt | sed -e 's/\.0   //g' -e 's/13..\.....  //' >> tsi_wls_mon.dat



$HOME/NINO/copyfiles.sh tsi_wls_???.dat
