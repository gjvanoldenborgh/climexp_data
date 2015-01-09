set size 0.745,0.5
set xrange [1995:2020]
set yrange [0:4]
set title '3-yr derivative of CO2 concentration [ppm/yr]'
set key left
plot 'diff_maunaloa_mean1.dat' title 'obs (Mauna Loa)' w l lt 5 lw 5, \
     'dtar-isam.txt' u 1:4 title 'A1FI' w l lt 1, \
     'dtar-isam.txt' u 1:2 title 'A1B' w l lt 4, \
     'dtar-isam.txt' u 1:5 title 'A2' w l lt 3, \
     'dtar-isam.txt' u 1:6 title 'B1' w l lt 2
#     , \
#     'dtar-bern.txt' u 1:4 notitle w l lt 1, \
#     'dtar-bern.txt' u 1:2 notitle w l lt 4, \
#     'dtar-bern.txt' u 1:5 notitle w l lt 3, \
#     'dtar-bern.txt' u 1:6 notitle w l lt 2
set term postscript epsf solid color
set out "plotdco2.eps"
replot
set term png font DejaVuSansCondensed 8.5 crop
set out "plotdco2.png"
replot
set term aqua
set out
!epstopdf plotdco2.eps
plot 'diff_maunaloa_mean1.dat' title 'obs (Mauna Loa)' w l lt 5 lw 5, \
     'diff_RCP85_CO2.dat' title 'RCP8.5' w l lt 1, \
     'diff_RCP6_CO2.dat' title 'RCP6.0' w l lt 4, \
     'diff_RCP45_CO2.dat' title 'RCP4.5' w l lt 3, \
     'diff_RCP3PD_CO2.dat' title 'RCP3PD' w l lt 2
set term postscript epsf solid color
set out "plotdco2rcp.eps"
replot
set term png font DejaVuSansCondensed 8.5 crop
set out "plotdco2rcp.png"
replot
set term aqua
set out
!epstopdf plotdco2rcp.eps
