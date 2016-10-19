#!/bin/sh
###set -x
dataset="$1"
if [ -z "$dataset" ]; then
    echo "usage: $0 gpcc|cmorph|erai"
    exit -1
fi
dir=$HOME/climexp
case $dataset in
    gpcc) file=$dir/GPCCData/gpcc_10_mon.nc;;
    cmorph) file=$dir/NCEPData/cmorph_monthly_1.nc;;
    erai) file=$dir/ERA-interim/erai_tp_daily_extended_mo.nc;;
    *) echo "$0: unknown dataset $dataset"; exit -1;;
esac
if [ ! -s $file ]; then
    echo "$0: error: cannot find file $file"
    exit -1
fi
month=0
files=""
while [ $month -lt 12 ]; do
    month=$((month+1))
    outfile=telecon_prcp_$month.dat
    patternfield $file corr_prcp_nino34.nc regr $month > $outfile
    files="$files $outfile"
done
./merge_telecon $files > telecon_nino34_$dataset.dat
rm $files
month=0
files=""
while [ $month -lt 12 ]; do
    month=$((month+1))
    outfile=telecon_corr_prcp_$month.dat
    patternfield $file corr_prcp_nino34.nc corr $month > $outfile
    files="$files $outfile"
done
./merge_telecon $files > telecon_corr_nino34_$dataset.dat
rm $files
$HOME/NINO/copyfilesall.sh telecon_nino34_$dataset.dat telecon_corr_nino34_$dataset.dat