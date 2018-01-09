#!/bin/sh
for var in TAVG TMIN TMAX
do
    case $var in
        TAVG) eraivar=t2m;;
        TMIN) eraivar=tmin;;
        TMAX) eraivar=tmax;;
    esac
    infile=${var}_Daily_LatLong1_full.nc
    eraidir=$HOME/climexp/ERA-interim/
    eraifile=$eraidir/erai_${eraivar}_daily_extended.nc
    erairegridded=erai_${eraivar}_daily_extended_regridded.nc
    outfile=${infile%.nc}_extended.nc
    if [ ! -s $erairegridded -o $erairegridded -ot $eraifile ]; then
        cdo -r -f nc4 -z zip remapbil,$infile $eraifile $erairegridded
    fi
    if [ ! -s $outfile -o $outfile -ot $erairegridded ]; then
        echo "patchfield $infile $erairegridded bias aap$$.nc"
        patchfield $infile $erairegridded bias aap$$.nc        
        averagefieldspace aap$$.nc 2 2 $outfile
        $HOME/NINO/copyfiles.sh $outfile
    fi
done
