#!/bin/bash
method=old
if [ $method  = 'old' ]; then
    # from the source code of http://projects.knmi.nl/klimatologie/uurgegevens/selectie.cgi
    base=http://projects.knmi.nl/klimatologie/uurgegevens
    yrnow=`date +%Y`
    if [ -s yr_hourly.txt ]; then
        yr=`cat yr_hourly.txt`
    else
        yr=$yrnow
    fi
    args="lang=nl&byear=$yr&bmonth=1&bday=1&eyear=$yr&emonth=12&eday=31&bhour=1&ehour=24&variabele=T&variabele=TD&variabele=RH"
    for station in 210 215 225 235 240 242 249 251 257 260 265 267 269 270 273 275 277 278 279 280 283 286 290 310 319 323 330 340 344 348 350 356 370 375 377 380 391
    do
        args="$args&stations=$station"
    done
    curl "$base/getdata_uur.cgi?$args" > KNMI_${yr}_hourly.txt
    echo $yrnow > yr_hourly.txt
    make hourly2maxdaily
    if [ ! -f rx260.dat -o rx260.dat -ot KNMI_${yr}_hourly.txt ]; then
        ./hourly2maxdaily KNMI_1???s_hourly.txt KNMI_2???_hourly.txt
    fi
elif [ $method = mew ]; then
    (cd ../KNMIUurData/update.sh; ./update.sh)
    for file in ../KNMIUurData/td???_hr.dat ../KNMIUurData/rh???_hr.dat
    do
        newfile=`basename $file .dat | sed -e 's/rh/rx'`
        daily2longer $file 366 max > $newfile
    done
    echo "generating tp (dewpoint 4 hours earlier) not yet ready"
fi
i=0
rm -f rx_??.dat rx_??.nc
rm -f tp_??.dat tp_??.nc
rm -f td_??.dat td_??.nc
for file in rx???.dat
do
    zfile=${file%.dat}.gz
    if [ ! -f $zfile -o $zfile -ot $file ]; then
        gzip -f -c $file > $zfile
    fi
    ncfile=${file%.dat}.nc
    if [ ! -f $ncfile -o $ncfile -ot $file ]; then
        station=${file#rx}
        station=${station%.dat}
        dat2nc $file p $station $ncfile
    fi

    if [ $i -lt 10 ]; then
        ii=0$i
    else
        ii=$i
    fi
    ln -s $ncfile rx_$ii.nc
    tfile=td${ncfile#rx}
    if [ ! -f $tfile -o $tfile -ot $file ]; then
        dat2nc ${tfile%.nc}.dat p $station $tfile
    fi
    ln -s $tfile td_$ii.nc
    tfile=tp${ncfile#rx}
    if [ ! -f $tfile -o $tfile -ot $file ]; then
        dat2nc ${tfile%.nc}.dat p $station $tfile
    fi
    ln -s $tfile tp_$ii.nc
    i=$((i+1))
done
average_ensemble rx_%%.nc num > rx_num.dat
$HOME/NINO/copyfiles.sh list_rx.txt list_t[dp].txt rx[^_]??.dat t[dp][^_]??.dat rx[^_]??.gz t[dp][^_]??.gz rx_num.dat
$HOME/NINO/copyfiles.sh rx_??.nc td_??.nc tp_??.nc
