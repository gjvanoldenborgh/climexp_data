#!/bin/sh
# process the netcdf files downloaded via BADC.
# give up on EH, WH files, but still produce lower-resolution versions.
# also make version with missing data when there rae no stations contributing.

# note that BADC requires you log in before downloading so I have to do that by hand

for var in tmp tmn tmx dtr pre vap cld
do
    file=cru_ts_3_10.1901.2009.$var.dat.nc
    if [ ! -s $file -o $file -ot $file.gz ]; then
	gunzip -f $file.gz
    fi
    [ ! -s $file ] && exit -1

    case $var in
	tmp|tmn|tmx|dtr) units="Celsius";;
	pre) units="mm/month";;
	*) units="";;
    esac
    if [ -n "$units" ]; then
	ncatted -a units,$var,m,c,"$units" $file
    fi

    file1=cru_ts_3_10_${var}_1.nc
    if [ ! -s $file1 -o $file1 -ot $file ]; then
	averagefieldspace $file 2 2 $file1
    fi

    file25=cru_ts_3_10_${var}_25.nc
    if [ ! -s $file25 -o $file1 -ot $file ]; then
	averagefieldspace $file 5 5 $file25
    fi

    rsync -e ssh $file $file1 $file25 bhlclim:climexp/CRUData/
done
