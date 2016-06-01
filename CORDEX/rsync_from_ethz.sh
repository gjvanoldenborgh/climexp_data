#!/bin/sh
export RSYNC_PASSWORD=donttelltoanybody
domains="EUR-44" # "EUR-11 MED-44 MED-11"
types="day" # "day fx mon"
fvars="areacella orog sftlf"
dvars="pr tas tasmin tasmax"
mvars="pr tas tasmin tasmax" # "tas tasmin tasmax pr evspsbl huss prw clwvi psl rlds rlus rlut rsds rsus rsdt rsut hfss hfls rldscs rlutcs rsdscs rsuscs rsutcs mrso mrro mrros snc"
avars3d="ta zg"
exps="historical rcp26 rcp45 rcp85"

for domain in $domains
do

    for exp in $exps
    do
        for type in $types
        do
            class=$type
            case $type in
                fx) vars=$fvars;;
                day) vars=$dvars;;
                mon3D) vars=$avars3d;class=mon;;
                mon) vars=$mvars;;
                *) echo "$0: error: unknown type $type"; exit -1;;
            esac
            for var in $vars
            do
                dir=$domain/$exp/$class/$var/
                mkdir -p ethz/$dir
                echo "============= $exp $model $var ==============="
                rsync -vrlpt c2sm-cordex@atmos.ethz.ch::cordex/$dir ethz/$dir
            done
        done
    done
done