#!/bin/bash
# this assumes Philippe downloads the updates.
yrnow=`date +%Y -d "2 months ago"`
[ "$1" = force  ] && force=true
cdo="cdo -r -f nc4 -z zip"
sourcedir=/net/pc170547/nobackup_2/users/sager/ERA5
vars=`ls $sourcedir/2010/mon/ | sed -e 's/era5_//' -e 's/_.*$//'`
filelist=""
for var in $vars; do
    case $var in
        q|rh|t|u|v|w|z) var="3d";;
    esac
    if [ $var != 3d ]; then
        ###sourcefiles="$sourcedir/????/mon/era5_${var}_*"
        sourcefiles=""
        yr=1978
        while [ $yr -lt $yrnow ]; do
            ((yr++))
            onefile=`echo $sourcedir/$yr/mon/era5_${var}_*`
            if [ -s "$onefile" ]; then
                sourcefiles="$sourcefiles $onefile"
            else
                sourcefiles=""
            fi
        done
        lastfile=`ls -t $sourcefiles | head -n 1`
        file=era5_${var}.nc
        if [ $lastfile -nt $file -o -n "$force" ]; then
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
        if [ ! -s $outfile -o $infile -nt $outfile -o -n "$force" ]; then
            $cdo monmean $infile $outfile
            filelist="$filelist $outfile"
        fi
    fi
done
if [ -n "$filelist" ]; then
    $HOME/NINO/copyfiles.sh $filelist
fi

# global means

for  var in t2m
do
    file=era5_$var.nc
    get_index $file 0 360 -90 90 standardunits > era5_${var}_gl.dat
    $HOME/NINO/copyfiles.sh $file
done
