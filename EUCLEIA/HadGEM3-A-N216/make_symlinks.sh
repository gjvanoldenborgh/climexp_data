#!/bin/sh
for scen in historical # historicalNat
do
    for var in pr # tasmin tasmax rx1day rx3day rx5day txx txn tnx txx
    do
        case $var in
            pr|tasmin|tasmax) scale=day;;
            rx?day|txx|txn|tnx|tnn) scale=yr;;
            *) echo "$0: error: cannot handle var $var yet";exit -1;;
        esac
        mkdir -p $scale/$var
        r=0
        p=1
        i=-1 # counter, not initialisation from rip
        shortruns=false
        while [ $i -lt 1000 ]; do
            i=$((i+1))
            iii=`printf %03i $i`
            if [ $shortruns = false ]; then
                r=$((r+1))
                for file in ${var}/${var}_${scale}_HadGEM3-A-N216_${scen}_r${r}i1p${p}_*.nc
                do
                    ###echo "Looking for $file"
                    if [ -f $file ]; then
                        newfile=`basename $file | sed -e "s/r${r}i1p${p}_//" -e "s/.nc/_$iii.nc/"`
                        [ -L $scale/$var/$newfile ] && rm $scale/$var/$newfile
                        echo "ln -s ../../$file $newfile"
                        (cd $scale/$var; ln -s ../../$file $newfile)
                    else
                        r=1
                        shortruns=true
                    fi
                done
                file=${var}_short/${var}_${scale}_HadGEM3-A-N216_${scen}Short_r${r}i1p${p}_20140101-20151230.nc
                if [ -f $file ]; then
                    newfile=`basename $file | sed -e "s/r${r}i1p${p}_//" -e "s/.nc/_$iii.nc/" -e "s/Short//"`
                    [ -L $scale/$var/$newfile ] && rm $scale/$var/$newfile
                    echo "ln -s ../../$file $newfile"
                    (cd $scale/$var; ln -s ../../$file $newfile)
                fi                
            fi
            if [ $shortruns = true ]; then            
                ((p++))
                file=${var}_short/${var}_${scale}_HadGEM3-A-N216_${scen}Short_r${r}i1p${p}_20140101-20151230.nc
                ###echo "Looking for $file"
                if [ -f $file ]; then
                    newfile=`basename $file | sed -e "s/r${r}i1p${p}_//" -e "s/.nc/_$iii.nc/" -e "s/Short//"`
                    [ -L $scale/$var/$newfile ] && rm $scale/$var/$newfile
                    echo "ln -s ../../$file $newfile"
                    (cd $scale/$var; ln -s ../../$file $newfile)
                else
                    ((r++))
                    p=2
                    file=${var}_short/${var}_${scale}_HadGEM3-A-N216_${scen}Short_r${r}i1p${p}_20140101-20151230.nc
                    ###echo "Looking for $file"
                    if [ -f $file ]; then
                        newfile=`basename $file | sed -e "s/r${r}i1p${p}_//" -e "s/.nc/_$iii.nc/" -e "s/Short//"`
                        [ -L $scale/$var/$newfile ] && rm $scale/$var/$newfile
                        echo "ln -s ../../$file $newfile"
                        (cd $scale/$var; ln -s ../../$file $newfile)
                    fi
                fi
            fi
        done
    done
done