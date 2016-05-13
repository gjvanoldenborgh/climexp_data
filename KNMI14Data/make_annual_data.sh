#!/bin/sh
# make annual derived data such as RXnday from the EC-Earth daily data
vars="rx1day rx3day rx5day txx txn tnx tnn"
for var in $vars; do
case $var in
    rx1day) invar=pr;args="max";;
    rx3day) invar=pr;args="max sum 3";;
    rx5day) invar=pr;args="max sum 5";;
    txx) invar=tasmax;args="max";;
    txn) invar=tasmax;args="min";;
    tnx) invar=tasmin;args="max";;
    tnn) invar=tasmin;args="min";;
    *) echo "$0: error: please give definition of $var";exit -1;;
esac

r=0
while [ $r -lt 16 ]; do
    r=$((r+1))
    indir=CMIP5/output/KNMI/ECEARTH23/rcp85/day/atmos/Amon/r${r}i1p1/v1/$invar
    outdir=CMIP5/output/KNMI/ECEARTH23/rcp85/yr/atmos/Amon/r${r}i1p1/v1/$var
    mkdir -p $outdir
    infiles=$indir/${invar}_day_ECEARTH23_rcp85_r${r}i1p1_*.nc
    outfiles=""
    varfile=${var}_yr_ECEARTH23_rcp85_r${r}i1p1_186001-210012.nc
    varfile=$outdir/$varfile
    if [ ! -s $varfile ]; then
        for infile in $infiles; do
            outfile=/tmp/${var}_`basename $infile`
            outfiles="$outfiles $outfile"
            if [ ! -s $outfile -o $outfile -ot $infile ]; then
                echo "daily2longerfield $infile 1 $args $outfile"
                daily2longerfield $infile 1 $args $outfile
                if [ $? != 0 -o ! -s $outfile ]; then
                    echo "something went wrong"
                    exit -1
                fi
            fi
        done
        echo "cdo -r -f nc4 -z zip copy $outfiles $varfile" 
        cdo -r -f nc4 -z zip copy $outfiles $varfile
        rm $outfiles
    fi
done
done # var
