set size 1,0.6
set xtics 1
set mxtics 12
set zeroaxis
set key left bottom
set title "CPC/NCEP ENSO indices"
set xrange [2003:2016]
set term postscript epsf color solid
set output 'plotninoweek0.eps'
set xrange [1990:2004]
plot 'wksst.myfor' using (1990+(7*$1-5)/365.25):($3) title 'NINO12 index' w lines lt 5 lw 1, \
     'wksst.myfor' using (1990+(7*$1-5)/365.25):($5) title 'NINO3 index' w lines lt 1 lw 5, \
     'wksst.myfor' using (1990+(7*$1-5)/365.25):($7) title 'NINO3.4 index' w lines lt 4 lw 5, \
     'wksst.myfor' using (1990+(7*$1-5)/365.25):($9) title 'NINO4 index' w lines lt 2 lw 3
set xrange [2004:2018]
set output 'plotninoweek.eps'
plot 'wksst.myfor' using (1990+(7*$1-5)/365.25):($3) title 'NINO12 index' w lines lt 5 lw 1, \
     'wksst.myfor' using (1990+(7*$1-5)/365.25):($5) title 'NINO3 index' w lines lt 1 lw 5, \
     'wksst.myfor' using (1990+(7*$1-5)/365.25):($7) title 'NINO3.4 index' w lines lt 4 lw 5, \
     'wksst.myfor' using (1990+(7*$1-5)/365.25):($9) title 'NINO4 index' w lines lt 2 lw 3
#set title 'NINO3 index'
#plot 'wksst.myfor' using (1990+(7*$1-5)/365.25):($5) notitle w lines lt 1 lw 3
#pause -1 "<cr> to continue"
#set title 'NINO3.4 index'
#plot 'wksst.myfor' using (1990+(7*$1-5)/365.25):($7) notitle w lines lt 1 lw 3
#pause -1 "<cr> to continue"
#set title 'NINO4 index'
#plot 'wksst.myfor' using (1990+(7*$1-5)/365.25):($9) notitle w lines lt 1 lw 3
#pause -1 "<cr> to continue"
