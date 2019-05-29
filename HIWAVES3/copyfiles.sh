#!/bin/bash
# copy the files from Karin's directory to here in a Climate-Explorer-friendly format

for exp in present future2C
do
    case $exp in
        present) sexp=PD;;
        future2C) sexp=2C;;
        *) echo "$0: error: unknown exp $exp"; exit -1;;
    esac
    for var in pr_d
    do
        svar=${var%_d}
        if [ $svar != $var ]; then
            time=Aday
        else
            time=Amon
        fi
        outdir=$time/$svar
        mkdir -p $outdir

        iens=0
        ens=`printf %03i $iens`
        s=0
        while [ $s -lt 16 ]; do
            ((s++))
            ss=`printf %02i $s`
            r=-1
            while [ $r -lt 24 ]; do
                ((r++))
                rr=`printf %02i $r`
                indir=/net/bhw402/nobackup_1/users/wiel/HiWAVES3/$exp/$var
                infiles=$indir/${var}_ECEarth_${sexp}_s${ss}r${rr}_????.nc
                outfile=$outdir/${svar}_${time}_ECEarth_${sexp}_$ens.nc
                if [ ! -s $outfile ]; then
                    for file in $infiles; do
                        if [ ! -s $file ]; then
                            echo "$0: error: cannot find file $file"
                            exit -1
                        fi
                    done
                    echo "cdo -r -f nc4 -z zip copy $infiles $outfile"
                    cdo -r -f nc4 -z zip copy $infiles $outfile
                fi
                ((iens++))
                ens=`printf %03i $iens`
            done # r
        done # s
    done # var
done # exp
