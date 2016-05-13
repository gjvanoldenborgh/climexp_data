#!/bin/sh
for scen in historical historicalNat; do
    for var in pr tasmin tasmax rx1day rx3day rx5day txx txn tnx txx
    do
        case $var in
            pr|tasmin|tasmax) scale=day;;
            rx?day|txx|txn|tnx|tnn) scale=yr;;
            *) echo "$0: error: cannot handle var $var yet";exit -1;;
        esac
        mkdir -p $scale/$var
        r=0
        i=-1
        while [ $i -lt 1000 ]; do
            r=$((r+1))
            i=$((i+1))
            iii=`printf %03i $i`
            ###echo ${var}/${var}_${scale}_HadGEM3-A-N216_${scen}_r${r}i1p1_*.nc
            for file in ${var}/${var}_${scale}_HadGEM3-A-N216_${scen}_r${r}i1p1_*.nc
            do
                if [ -f $file ]; then # this skips all $i that are too large
                    newfile=`basename $file | sed -e "s/r${r}i1p1_//" -e "s/.nc/_$iii.nc/"`
                    [ -L $scale/$var/$newfile ] && rm $scale/$var/$newfile
                    (cd $scale/$var; ln -s ../../$file $newfile)
                fi
            done
        done
    done
done