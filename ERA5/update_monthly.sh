#!/bin/sh
# this assumes Philippe downloads the updates.
cdo="cdo -r -f nc4 -z zip"
sourcedir=/net/pc170547/nobackup_2/users/sager/ERA5
vars=`ls $sourcedir/2010/mon/ | sed -e 's/era5_//' -e 's/_.*$//'`
filelist=""
for var in $vars; do
    case $var in
        q|rh|t|u|v|w|z) var="3d";;
    esac
    if [ $var != 3d ]; then
        sourcefiles="$sourcedir/????/mon/era5_${var}_*"
        lastfile=`ls -t $sourcefiles | head -n 1`
        file=era5_${var}.nc
        if [ $lastfile -nt $file ]; then
            echo $var
            $cdo copy $sourcefiles $file
            . $HOME/climexp/add_climexp_url_field.cgi
            filelist="$filelist $file"
        fi
    fi
done
for var in tmin tmax; do
    infile=era5_${var}_daily.nc
    outfile=era5_${var}.nc
    if [ -s $infile ]; then
        if [ ! -s $outfile -o $infile -nt $outfile ]; then
            $cdo monmean $infile $outfile
            filelist="$filelist $outfile"
        fi    
    fi
done
if [ -n "$filelist" ]; then
    rsync -v $filelist bhlclim:climexp/ERA5/
fi
