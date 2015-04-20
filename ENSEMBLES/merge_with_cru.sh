#!/bin/sh
[ -z "$version" ] && echo "$0: error: please define version" && exit -1
cversion=3.22
for var in tg tx tn rr
do
    file=${var}_0.50deg_reg_${version}u.nc
    monfile=${var}_0.50deg_reg_${version}u_mon.nc
    outfile=${var}_0.50deg_reg_${version}u_extended.nc
    case $var in
        tg) ccfile=`ls -t ../CRUData/cru_ts$cversion.1901.2???.tmp.dat.nc | head -1`;;
        tx) ccfile=`ls -t ../CRUData/cru_ts$cversion.1901.2???.tmx.dat.nc | head -1`;;
        tn) ccfile=`ls -t ../CRUData/cru_ts$cversion.1901.2???.tmn.dat.nc | head -1`;;
        rr) ccfile=`ls -t ../CRUData/cru_ts$cversion.1901.2???.pre.dat.nc | head -1`;;
        *) echo "cannot handle $var yet"; exit -1;;
    esac
    if [ -z "$ccfile" -o ! -s "$ccfile" ]; then
        echo "cannot find CRU file $ccfile"
        exit -1
    fi
    cfile=`basename $ccfile`
    if [ ! -s $cfile -o $cfile -ot ../CRUData/$cfile ]; then
        cdo sellonlatbox,-40.5,75.5,25.,75.5 ../CRUData/$cfile ./$cfile
    fi
    if [ ! -s $monfile -o $monfile -ot $file ]; then
        daily2longerfield $file 12 mean $monfile
    fi
    if [ ! -s $outfile -o $outfile -ot $monfile -o $outfile -ot $cfile ]; then
        patchfield $monfile $cfile $outfile
    fi
    $HOME/NINO/copyfiles.sh $outfile
done
