#!/bin/sh
export PATH=$PATH:/usr/people/oldenbor/climexp/bin/
export DIR=$HOME/climexp
scp bvlclim:climexp/NASAData/giss_al_gl_a_4yrlo.dat $HOME/NINO/NASAData/
for station in 240 260 275 280 283 344 350 370 375 380
do
    case $station in
        260) homfile=temp_De_Bilt_hom;;
        283) homfile=temp_Winterswijk_Hupsel_hom;;
        350) homfile=temp_Oudenbosch_Gilze-Rijen_hom;;
        375) homfile=temp_Gemert_Volkel_hom;;
        275) homfile=temp_Deelen_hom;;
        370) homfile=temp_Eindhoven_hom;;
        380) homfile=temp_Maastricht_Beek_hom;;
        344) homfile=temp_Rotterdam_hom;;
        240) homfile=temp_Schiphol_hom;;
        280) homfile=temp_Groningen_Eelde_hom;;
        *) echo error oiuhlyfuv; exit -1;;
    esac
    dayfile=tg$station.dat
    monfile=tg${station}_mean12.dat
    if [ $monfile -ot $dayfile -o ! -s $monfile ]
    then
        daily2longer $dayfile 12 mean add_trend > $monfile
        c=`cat $monfile | wc -l | tr -d ' '`
        if [ $c -lt 20 ]; then
            echo "Something went wrong in"
            echo daily2longer $dayfile 12 mean add_trend
            wc $monfile
            exit
        fi
    fi
    cp $homfile.dat.org $homfile.dat
    egrep '^ *(2009|20[1-9].)' $monfile >> $homfile.dat
    [ -L temp$station.dat ] && rm temp$station.dat
    ln -s $homfile.dat temp$station.dat # for getdutchtemp
done
./maketxt_hom.sh

make makecnt
mv cnt.dat cnt.dat.old
./makecnt > cnt.dat
mv cnt_v11.dat cnt_v11.dat.old
./makecnt 1.1 > cnt_v11.dat
averageseries const temp_De_Bilt_hom.dat temp_Winterswijk_Hupsel_hom.dat \
                    temp_Oudenbosch_Gilze-Rijen_hom.dat temp_Gemert_Volkel_hom.dat > cnt4.dat

$HOME/NINO/copyfiles.sh cnt*.dat temp*.dat list_temp_hom.txt