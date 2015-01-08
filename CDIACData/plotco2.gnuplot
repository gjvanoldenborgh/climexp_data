set size 0.745,0.5
set xrange [1995:2015]
set yrange [360:405]
set key left
plot 'co2_annual.dat' title 'obs (global marine)' w l lt 5 lw 5, \
     'tar-isam.txt' u 1:4 title 'A1FI' w l lt 1, \
     'tar-isam.txt' u 1:2 title 'A1B' w l lt 4, \
     'tar-isam.txt' u 1:5 title 'A2' w l lt 3, \
     'tar-isam.txt' u 1:6 title 'B1' w l lt 2, \
     'tar-bern.txt' u 1:4 notitle w l lt 1, \
     'tar-bern.txt' u 1:2 notitle w l lt 4, \
     'tar-bern.txt' u 1:5 notitle w l lt 3, \
     'tar-bern.txt' u 1:6 notitle w l lt 2
set term postscript epsf solid color
set out "plotco2.eps"
replot
set term png font DejaVuSansCondensed 8.5 crop
set out "plotco2.png"
replot
set term aqua
set out
!epstopdf plotco2.eps
plot 'co2_annual.dat' title 'obs (global marine)' w l lt 5 lw 5, \
     'RCP85_CO2.dat' title 'RCP8.5' w l lt 1, \
     'RCP6_CO2.dat' title 'RCP6.0' w l lt 4, \
     'RCP45_CO2.dat' title 'RCP4.5' w l lt 3, \
     'RCP3PD_CO2.dat' title 'RCP3PD' w l lt 2
set term postscript epsf solid color
set out "plotco2rcp.eps"
replot
set term png font DejaVuSansCondensed 8.5 crop
set out "plotco2rcp.png"
replot
set term aqua
set out
!epstopdf plotco2rcp.eps
