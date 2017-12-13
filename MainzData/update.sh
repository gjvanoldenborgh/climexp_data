#!/bin/sh
# update the hiomogenised time series from Haparanda SE from U Mainz with ECA&D data
# note tha tthe two stations there, Haparanda 339 and Haparanda_A 5794 are identical over 2015-now

for var in tg tn tx; do
    case $var in
        tg) lvar=MeanTemperature;prog=ecatemp;;
        tn) lvar=MinimumTemperature;prog=ecatmin;;
        tx) lvar=MaximumTemperature;prog=ecatmax;;
    esac
    # make monthly time series 2015-now from ECA&D data
    (cd $HOME/climexp; export DIR=$HOME/climexp; ./bin/$prog 339) > ${var}339_daily.dat
    daily2longer ${var}339_daily.dat 12 mean > ${var}339.dat
    file=Haparanda_${lvar}_corr_ext.dat
    cat > $file <<EOF
# Homoegenised temperature time series from <a href="MainzData/Dienst_et_al-2017-International_Journal_of_Climatology.pdf">Dienst et al, 2017</a>
# extended with  <a href="http://www.ecad.eu">ECAD data</a> from SMHI.
# Haparanda, Sweden, 65.83N, 24.14E, 5.0m, 1859-now
# $var [Celsius] $lvar
EOF
    tail +2 Haparanda_${lvar}_corr_monthly.txt >> $file
    egrep ' *201[5-9]|^ 20[2-9]' ${var}339.dat >> $file
    $HOME/copyfiles.sh $file
done