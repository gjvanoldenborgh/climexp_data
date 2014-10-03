#!/bin/sh
wget -N http://www.pmel.noaa.gov/tao/elnino/wwv/data/wwv.dat

egrep -v '^[12 ]' wwv.dat | sed -e 's/^/# /' > tao_wwv.dat
echo '# <a href="http://www.pmel.noaa.gov/tao/elnino/wwv/data/wwv.dat">source</a>' >> tao_wwv.dat
echo '# WWV [m^3] Warm Water Volume 5N-5S, 120E-80W' >> tao_wwv.dat
egrep '^[12]' wwv.dat | awk '{print $1 " " $2}' >> tao_wwv.dat

egrep -v '^[12 ]' wwv.dat | sed -e 's/^/# /' > tao_wwva.dat
echo '# <a href="http://www.pmel.noaa.gov/tao/elnino/wwv/data/wwv.dat">source</a>' >> tao_wwva.dat
echo '# WWVa [m^3] Warm Water Volume anomalies 5N-5S, 120E-80W' >> tao_wwva.dat
egrep '^[12]' wwv.dat | awk '{print $1 " " $3}' >> tao_wwva.dat

$HOME/NINO/copyfiles.sh tao_wwv.dat tao_wwva.dat