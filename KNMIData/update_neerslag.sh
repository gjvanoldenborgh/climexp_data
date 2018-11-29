#!/bin/sh
# update the 8-8 precipitation data from the volunteer stations
force=false
[ "$1" == force ] && force=true
[ ! -d tmp ] && mkdir tmp
[ ! -d webreeksen ] && mkdir webreeksen
wget -q -N https://cdn.knmi.nl/knmi/map/page/klimatologie/gegevens/monv_reeksen/neerslaggeg_DE-BILT_550.zip
cmp neerslaggeg_DE-BILT_550.zip webreeksen/neerslaggeg_DE-BILT_550.zip
if [ $? != 0 -o $force = true ]; then
    files=`curl https://www.knmi.nl/nederland-nu/klimatologie/monv/reeksen | fgrep .zip | sed -e 's@^.*monv_reeksen/@@' -e 's/zip.*$/zip/'`
    nstations=`echo $files | wc -w`
    echo "nstations=$nstations"
    ((nstations++)) # Amsterdam filiaal wordt met de hand toegevoegd
    echo "located $nstations stations in 50.0N:54.0N, 3.0E:8.0E" > list_rr.txt
    echo '==============================================' >> list_rr.txt
    echo "located $nstations stations in 50.0N:54.0N, 3.0E:8.0E" > list_sd.txt
    echo '==============================================' >> list_sd.txt
    for file in $files; do
        wget -q https://cdn.knmi.nl/knmi/map/page/klimatologie/gegevens/monv_reeksen/$file
        mv $file webreeksen/
        if [ -s "webreeksen/$file" ]; then
            echo "updating from $file"
            txtfile=tmp/`basename $file .zip`.txt
            unzip -p webreeksen/$file > $txtfile
            (./neerslag2dat $txtfile >> list_rr.txt) >> list_sd.txt 2>&1
        else
            echo "$0: error: cannot find $file"
        fi
    done
    # (at least) one missing station...
    cat <<EOF > rr433.dat
# THESE DATA CAN BE USED FREELY PROVIDED THAT THE FOLLOWING SOURCE IS ACKNOWLEDGED: ROYAL NETHERLANDS METEOROLOGICAL INSTITUTE
# 43 Amsterdam KNMI-filiaal (  -999.9N,    999.9E)
# precip [mm/dy] precipitation (8-8), added by hand to database
# time refers to the day it is observed, 8UTC
EOF
    fgrep 433, AmsFil.txt | sed -e 's/433,//' -e 's/,   0[0-9]//' -e 's/,//' >> rr433.dat
    cat <<EOF >> list_rr.txt
Amsterdam Filiaal                       (Netherlands)
coordinates:   -999.90N,   -999.90E
station code: 433 Amsterdam Filiaal
Found   11 years with data in 1951-1961
==============================================
EOF

    # first-order fix for the problems with the manual gauges
    ./fix_manual_gauges
    rm sd???.dat.org
    ###./fix_sd.sh  # snow depth data has been fixed upstream 19-oct-2018

    for file in rr???.dat sd???.dat sdhom???.dat
    do
        c=`cat $file | wc -l`
        if [ -z "$c" ]; then
            rm -f $file ${file%.dat}.gz ${file%.dat}.nc
        elif [ "$c" -lt 20 ]; then
            rm -f $file ${file%.dat}.gz ${file%.dat}.nc
        else
            zfile=${file%.dat}.gz
            gzip -f -c $file > $zfile
        fi
    done

    # make netcdf files
    for file in sd???.dat
    do
        ncfile=${file%.dat}.nc
        if [ ! -s $ncfile -o $ncfile -ot $file ]; then
            station=`head -n 20 $file | fgrep 'station_name :: ' | sed -e 's/.*:: //'` 
            echo dat2nc $file s "$station" $ncfile
            dat2nc $file i "$station" $ncfile
        fi
    done
    ./makehom_sd.sh
    for file in sdhom???.dat
    do
        ncfile=${file%.dat}.nc
        if [ ! -s $ncfile -o $ncfile -ot $file ]; then
            station=`head -n 20 $file | fgrep 'station_name :: ' | sed -e 's/.*:: //'` 
            echo dat2nc $file s "$station" $ncfile
            dat2nc $file i "$station" $ncfile
        fi
    done

    # make links to an ensemble
    rm -f rh242.dat rh340.dat
    rm -f rr_???.nc rrr_???.nc
    i=0
    for file in rr???.dat rh???.dat # grote hoop
    do
        ii=`printf %3.3i $i`
        ncfile=${file%.dat}.nc
        if [ ! -s $ncfile -o $ncfile -ot $file ]; then
            if [ ${file#rr} != $file ]; then
                station=`head -2 $file | tail -1 | sed -e 's/# //' -e 's/ [(].*//' -e 's/ /_/g'`
            elif [ ${file#rh} != $file ]; then
                station=`head -3 $file | tail -1 | sed -e 's/# //' -e 's/ [(].*//' -e 's/ /_/g'`
            else
                echo "$0: internal error"; station=unknown
            fi
            echo dat2nc $file p "$station" $ncfile
            dat2nc $file p "$station" $ncfile
        fi
        lfile=rrr_$ii.nc
        ln -s $ncfile $lfile
        i=$((i+1))
    done
    i=0
    for file in rr???.dat # alleen 8-8 stations
    do
        ii=`printf %3.3i $i`
        ncfile=${file%.dat}.nc
        lfile=rr_$ii.nc
        ln -s $ncfile $lfile
        i=$((i+1))
    done
    average_ensemble rr_%%%.nc max > rr_max.dat
    average_ensemble rrr_%%%.nc max > rrr_max.dat
    average_ensemble rr_%%%.nc num > rr_num.dat
    average_ensemble rrr_%%%.nc num > rrr_num.dat
    $HOME/NINO/copyfiles.sh list_rr.txt rr???.?? rh???.nc rrr_max.dat rrr_num.dat rr_max.dat rr_num.dat
    $HOME/NINO/copyfiles.sh list_sd.txt sd???.??
    rsync -avt rr_???.nc bhlclim:climexp/KNMIData/
    
    ./make_p13.sh
fi