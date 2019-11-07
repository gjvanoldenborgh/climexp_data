#!/bin/sh
# process Kevin Cowtan's blended tas/tos CMIP5 temperature global averages at http://www-users.york.ac.uk/~kdc3/papers/robust2015/methods.html
mkdir -p blended
cd blended
# delete all symlinks
for file in *.dat *.nc; do
    [ -L $file ] && rm $file
done

###set -x
for scenario in rcp45 rcp85; do
    for type in xxx mxx; do
        case $type in
            xxx) typename="unmasked, absolute temperatures, variable ice";;
            mxx) typename="masked, absolute temperatures, variable ice";;
            xax) typename="unmasked, temperature anomalies, variable ice";;
            max) typename="masked, temperature anomalies, variable ice";;
            xxf) typename="unmasked, absolute temperatures, fixed ice";;
            mxf) typename="masked, absolute temperatures, fixed ice";;
            xaf) typename="unmasked, temperature anomalies, fixed ice";;
            maf) typename="masked, temperature anomalies, fixed ice";;
            had4) typename="HadCRUT4 emulation";;
            *) echo "$0: error: unknown type $type"; exit -1;;
        esac
        models=""
        oldmodel=oldmodel
        iens=-1
        for file in ../${scenario}-${type}/${scenario}_*.temp; do
            string=${file#*_}
            model=${string%*_}
            model=${model%_*}
            if [ $model != $oldmodel ]; then
                oldmodel=$model
                iensmod=-1
            fi
            rip=${string#*_}
            rip=${rip%.temp}
            echo model,rip = $model,$rip
            if [ $model = BNU-ESM -o $model = CMCC-CESM -o $model = bcc-csm1-1-m ]; then
                echo "Skipping model $model"
            else
                datfile=blended_${model}_${scenario}-${type}_${rip}.dat
                ncfile=${datfile%.dat}.nc
                if [ ! -s $datfile ]; then
                    cat <<EOF > $datfile
# tastos [K] blended t2m/SST $model ${scenario}-${type} $rip
# $typename
# source :: http://www-users.york.ac.uk/~kdc3/papers/robust2015/methods.html
# reference :: Kevin Cowtan, Zeke Hausfather, Ed Hawkins, Peter Jacobs, Michael E. Mann, Sonya K. Miller, Byron Steinman, Martin B. Stolpe, Robert G. Way, Robust comparison of climate models with observations using blended land air and ocean sea surface temperatures, GRL, 2015. doi:10.1002/2015GL064888
# contact :: kevin.cowtan@york.ac.uk
# institution :: University of York
EOF
                    cut -d " " -f 1,3 $file >> $datfile
                fi
                if [ ! -s $ncfile -o $ncfile -ot $datfile ]; then
                    dat2nc $datfile i blended_${model}_${scenario}-${type}_${rip} $ncfile
                    if [ ! -s $ncfile ]; then
                        echo "$0: error: something went wrong generating $ncfile"
                        exit -1
                    fi
                fi
                models="$models $model"
                
#               ensemble of all members
                
                ((iens++))
                ens=`printf %03i $iens`
                ensfile=blended_ens_${scenario}-${type}_${ens}.dat
                ln -s $datfile $ensfile
                ln -s $ncfile ${ensfile%.dat}.nc

#               ensemble of all members of one model

                ((iensmod++))
                ens=`printf %03i $iensmod`
                ensfile=blended_${model}_${scenario}-${type}_${ens}.dat
                ln -s $datfile $ensfile
                ln -s $ncfile ${ensfile%.dat}.nc
            fi # valid model
        done # file

#       loop ove rall models

        imod=-1
        models=`echo $models | tr ' ' '\n' | uniq`
        echo models=$models
        for model in $models; do
            modelfile=blended_${model}_${scenario}-${type}_ave.dat
            modelfiles=blended_${model}_${scenario}-${type}_%%%.dat
            if [ ! -L blended_${model}_${scenario}-${type}_001.dat ]; then
                # only one member
                echo "ln -s blended_${model}_${scenario}-${type}_000.dat $modelfile"
                ln -s blended_${model}_${scenario}-${type}_000.dat $modelfile
                ln -s blended_${model}_${scenario}-${type}_000.nc ${modelfile%.dat}.nc
            elif [ ! -s $modelfile ]; then
                echo "average_ensemble $modelfiles mean > $modelfile"
                average_ensemble $modelfiles mean > $modelfile
                if [ ! -s $modelfile ]; then
                    echo "$0: error in generating $modelfile"
                    exit -1
                fi
            fi
            if [ ! -s ${modelfile%.dat}.nc ]; then
                dat2nc $modelfile i blended_${model}_${scenario}-${type}_ave ${modelfile%.dat}.nc
            fi
            ((imod++))
            ens=`printf %03i $imod`
            ensfile=blended_model_${scenario}-${type}_${ens}.dat
            ln -s $modelfile $ensfile
            ln -s ${modelfile%.dat}.nc ${ensfile%.dat}.nc
        done # models

#       and the multi-model mean

        avefile=blended_model_${scenario}-${type}_ave.dat
        if [ ! -s $avefile ]; then
            echo "average_ensemble blended_model_${scenario}-${type}_%%%.dat mean > $avefile"
            average_ensemble blended_model_${scenario}-${type}_%%%.dat mean > $avefile
             if [ ! -s $modelfile ]; then
                echo "$0: error in generating $avefile"
                exit -1
            fi
        fi
        if [ ! -s ${avefile%.dat}.nc ]; then
            dat2nc $avefile i blended_model_${scenario}-${type}_ave ${avefile%.dat}.nc
        fi
    done
done
