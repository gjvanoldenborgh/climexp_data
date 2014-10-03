#!/bin/sh
# http://figshare.com/articles/GIDMaPS_Data/853801
# the up-to-date data do not seem to be publicly available
i=1508758
for var in PSI SPI SSI
do
    case $var in
        PSI|SSI) datasets="GLDAS MERRA NLDAS";;
        SPI) datasets="GDCDR GLDAS MERRA NLDAS";;
        *) echo "$0: error: unknown var $car";exit -1;;
    esac
    for dataset in $datasets
    do
        cp ${var}_${dataset}.zip ${var}_${dataset}.zip.old
        [ $i = 1508762 ] && i=1508767
        [ $i = 1508768 ] && i=1508770        
        [ $i = 1508773 ] && i=1508778        
        wget -N http://files.figshare.com/$i/${var}_${dataset}.zip
        if [ ! -s ${var}_${dataset}.zip ]; then
            echo "Something went wrong in retrieving ${var}_${dataset}.zip"
            exit -1
        fi
        i=$((i+1))
        cmp ${var}_${dataset}.zip ${var}_${dataset}.zip.old
        if [ $? != 0 -o ! -s ${var}_${dataset}.nc ]; then
            unzip ${var}_${dataset}.zip
            # my Fortran still spews out classic netcdf
            ./asc2nc $var $dataset
            # gain a factor 4-5...
            cdo -r -f nc4 -z zip copy ${var}_${dataset}.nc aap.nc
            mv aap.nc ${var}_${dataset}.nc
            # clean up
            rm -rf ${var}_${dataset}/
        fi
    done
done