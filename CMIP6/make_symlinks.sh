#!/bin/bash
# make link farm to convert the CMIP6 ensembles from my conventions to Joost's conventions

server=/data/climexp_cmip6/CE
iserver=/data/climexp_cmip6/CEinterpolated
models=`ls $server`
ssps="126 245 370 585"
# CanESM5 has p2, here is no p3
# CNRM-CM6-1, CNRM-ESM2-1, MCM-UA-1-0, MIROC-ES2L, UKESM1-0-LL have f2, no f3.
# there are no i2 (of course)
vars="pr psl tas tasmin tasmax"

for var in $vars; do
    case $var in
        pr) inttype=con;;
        *) inttype=bil;;
    esac
    pwd=`pwd`
    mkdir -p monthly/$var
    cd monthly/$var
    
#   per model ensembles
    
    for model in $models; do
        modelname=$model
        dir=$server/$model/r1i1p2f?
        if [ -d $dir ]; then
            ps="1 2"
            modelname=${modelname}_$p
        else
            ps=1
        fi
        for p in $ps; do
            dir=$server/$model/r1i1p1f2
            if [ -d $dir ]; then
                fs="1 2"
                modelname=${modelname}_$f
            else
                fs=1
            fi
            for f in $fs; do
                for ssp in $ssps; do
                    iens=0
                    r=1
                    echo "checking for $server/$model/r1i1p${p}f${f}"
                    while [ -d $server/$model/r${r}i1p${p}f${f} ]; do
                        ens=`printf %02i $iens`
                        file=$server/$model/r${r}i1p${p}f${f}/${var}_Amon_${model}_historical+ssp${ssp}_r${r}i1p${p}f${f}_gn_??????-??????+??????-??????_CEmerged.nc
                        if [ ! -s $file ]; then
                            echo "$0: warning: cannot find $file"
                        else
                            linkfile=`basename $file .nc | sed -e "s/r${r}i1/i1/" -e "s/historical.//"`_$ens.nc
                            [ -L $linkfile ] && rm $linkfile
                            echo "ln -s $file $linkfile"
                            ln -s $file $linkfile
                        fi
                        ((r++))
                        ((iens++))
                    done # r
                done # ssp
            done # f
        done # p
    done # model

#   overall ensembles: one ensemble member per model

    for ssp in $ssps; do
        iens=0
        for model in $models; do
            modelname=$model
            dir=$iserver/$model/r1i1p2f?
            if [ -d $dir ]; then
                ps="1 2"
                modelname=${modelname}_$p
            else
                ps=1
            fi
            for p in $ps; do
                dir=$iserver/$model/r1i1p1f2
                if [ -d $dir ]; then
                    fs="1 2"
                    modelname=${modelname}_$f
                else
                    fs=1
                fi
                for f in $fs; do
                    file=$iserver/$model/r1i1p${p}f${f}/${var}_Amon_${model}_historical+ssp${ssp}_r1i1p${p}f${f}_gn_??????-??????+??????-??????_CEmerged_${inttype}288x144lonlat.nc
                    if [ ! -s $file ]; then
                        echo "$0: warning: cannot find $file"
                    else
                        ens=`printf %03i $iens`
                        linkfile=${var}_Amon_one_ssp${ssp}_gn_185001-210012_$ens.nc
                        [ -L $linkfile ] && rm $linkfile
                        echo "ln -s $file $linkfile"
                        ln -s $file $linkfile
                        ((iens++))
                    fi
                done # f
            done # p
        done # model
    done # ssp

#   overall ensembles: all ensemble members

    for ssp in $ssps; do
        iens=0
        for model in $models; do
            modelname=$model
            dir=$iserver/$model/r1i1p2f?
            if [ -d $dir ]; then
                ps="1 2"
                modelname=${modelname}_$p
            else
                ps=1
            fi
            for p in $ps; do
                dir=$iserver/$model/r1i1p1f2
                if [ -d $dir ]; then
                    fs="1 2"
                    modelname=${modelname}_$f
                else
                    fs=1
                fi
                for f in $fs; do
                    r=1
                    echo "checking for $iserver/$model/r1i1p${p}f${f}"
                    while [ -d $iserver/$model/r${r}i1p${p}f${f} ]; do
                    
                        file=$iserver/$model/r${r}i1p${p}f${f}/${var}_Amon_${model}_historical+ssp${ssp}_r${r}i1p${p}f${f}_gn_??????-??????+??????-??????_CEmerged_${inttype}288x144lonlat.nc
                        if [ ! -s $file ]; then
                            echo "$0: warning: cannot find $file"
                        else
                            ens=`printf %03i $iens`
                            linkfile=${var}_Amon_ens_ssp${ssp}_gn_185001-210012_$ens.nc
                            [ -L $linkfile ] && rm $linkfile
                            echo "ln -s $file $linkfile"
                            ln -s $file $linkfile
                            ((iens++))
                        fi
                        ((r++))
                    done # r
                done # f
            done # p
        done # model
    done # ssp

#   and go back

    cd $pwd
done # var