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

    for scen in historical historicalNat; do
        r=0
        while [ $r -lt 15 ]; do
            r=$((r+1))
            indir=$invar/
            outdir=$var
            mkdir -p $outdir
            infiles=$indir/${invar}_day_HadGEM3-A-N216_${scen}_r${r}i1p1_*.nc
            infile=`ls $infiles|head -1`
            if [ ! -s "$infile" ]; then
                infiles=$indir/${invar}_day_HadGEM3-A-N216_${scen}_r1i1p${r}_*.nc
            fi
            outfiles=""
            varfile=${var}_yr_HadGEM3-A-N216_${scen}_r${r}i1p1_196001-201312.nc
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
    done # scen
done # var
