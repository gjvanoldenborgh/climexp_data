#!/bin/sh
# make a few nice plots

daily2longer maunaloa_f.dat 1 mean add_trend > maunaloa_f_mean1.dat
diffdat maunaloa_f_mean1.dat 3 > diff_maunaloa_mean1.dat
diffdat co2_annual.dat 3 > diff_co2_annual.dat
for scen in RCP3PD RCP45 RCP6 RCP85
do
    [ ! -s diff${scen}_CO2.dat ] && diffdat ${scen}_CO2.dat 3 > diff_${scen}_CO2.dat
done
gnuplot plotco2.gnuplot
gnuplot plotdco2.gnuplot
