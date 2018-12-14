#!/bin/bash
for var in prmsl
do
    case $var in
        prmsl) nvar=slp;;
        *) echo "$0: error: unknown var $var"; exit -1;;
    esac
    cfile=$var.mon.mean.nc
    nnfile=$nvar.mon.mean.nc
    nfile=$HOME/NINO/NCEPNCAR40/$nnfile
    efile=$var.mon.mean_extended.nc

    cdo remapbil,$cfile $nfile $nnfile
    patchfield $cfile $nnfile $efile
    $HOME/NINO/copyfiles.sh $efile
done
