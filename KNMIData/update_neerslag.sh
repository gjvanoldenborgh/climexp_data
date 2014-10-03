#!/bin/sh
# update the 8-8 precipitation data from the volunteer stations
[ ! -d tmp ] && mkdir tmp
if [ ! -s rr550.dat -o reeksen/neerslaggeg_550.zip -nt rr550.dat ]; then
    echo 'located stations in 50.0N:54.0N, 3.0E:8.0E' > list_rr.txt
    echo '==============================================' >> list_rr.txt
    for file in reeksen/neerslaggeg_*.zip
    do
        txtfile=tmp/`basename $file .zip`.txt
        unzip -p $file > $txtfile
        ./neerslag2dat $txtfile >> list_rr.txt
    done
    # (at least) one missing station...
    if [ ! -s rr433.dat ]; then
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
    fi
    for file in rr???.dat
    do
        zfile=${file%.dat}.gz
        gzip -f -c $file > $zfile
    done
###fi
###if [ 0 = 0 ]; then
    # link farm
    # make links to an ensemble
    rm -f rh242.dat rh340.dat
    rm -f rr_???.nc rrr_???.nc
    i=0
    for file in rr???.dat rh???.dat # grote hoop
    do
        ii=`printf %3.3i $i`
        ncfile=${file%.dat}.nc
        if [ ! -s $ncfile -o $ncfile -ot $file ]; then
            station=`head -2 $file | tail -1 | sed -e 's/# //' -e 's/ [(].*//' -e 's/ /_/g'`
            ###echo dat2nc $file p $station $ncfile
            dat2nc $file p $station $ncfile
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
    rsync -avt rr_???.nc bhlclim:climexp/KNMIData/
fi