#!/bin/bash
gfortran -o ninoreconstruction2dat ninoreconstruction2dat.f90
for type in NCT NWP; do
    case $type in
        NCT) longname="Niño Cold Tongue";col=3;;
        NWP) longname="Niño Warm Pool index";col=4;;
        *) echo "$0: unknow type $type";exit -1;;
    esac
    infile=Index_Reconstructions.txt
    outfile=CSIRO_$type.dat
    cat > $outfile <<EOF
# $type [1] $longname
# title :: 400 Year Reconstruction of Niño Cold Tongue and Niño Warm Pool Index
# institution :: CSIRO
# contact :: Mandy.Freund@csiro.au
# references :: Freund, M. B., Henley, B. J., Karoly, D. J., McGregor, H. V., Abram, N. J. and Dommenget, D. (2019) Higher frequency of Central Pacific El Niño events in recent decades relative to past centuries, Nature Geoscience, doi:10.1038/s41561-019-0353-3
# source_url :: https://www.ncdc.noaa.gov/paleo/study/26270
EOF
    ./ninoreconstruction2dat $infile $col >> $outfile   
done