#!/bin/sh
# from the source code of http://www.knmi.nl/klimatologie/uurgegevens/selectie.cgi
base=http://www.knmi.nl/klimatologie/uurgegevens
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
if [ ! -f hourly2maxdaily -o hourly2maxdaily -ot hourly2maxdaily.f ]; then
    gfortran -o hourly2maxdaily hourly2maxdaily.f
fi
if [ ! -f rx260.dat -o rx260.dat -ot KNMI_2014_hourly.txt ]; then
    ./hourly2maxdaily KNMI_1???s_hourly.txt KNMI_2???_hourly.txt
fi
i=0
rm rx_??.dat
rm tp_??.dat
rm td_??.dat
for file in rx???.dat td???.dat
do
    zfile=${file%.dat}.gz
    if [ ! -f $zfile -o $zfile -ot $file ]; then
        gzip -f -c $file > $zfile
    fi
    if [ $i -lt 10 ]; then
        ii=0$i
    else
        ii=$i
    fi
    ln -s $file rx_$ii.dat
    tfile=td${file#rh}
    ln -s $tfile td_$ii.dat
    tfile=tp${file#rh}
    ln -s $tfile tp_$ii.dat
    i=$((i+1))
done
$HOME/NINO/copyfiles.sh list_rx.txt list_t[dp].txt rx[^_]??.dat t[dp][^_]??.dat rx[^_]??.gz t[dp][^_]??.gz 