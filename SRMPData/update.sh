#!/bin/sh
wget -q -N ftp://ftp.geolab.nrcan.gc.ca/data/solar_flux/monthly_averages/solflux_monthly_average.txt
echo "# Observed solar radia flux at 10.7cm from <a href="http://www.spaceweather.ca/sx-eng.php">Space Weather Canada</a>" > solarradioflux.dat
tail -n +3 solflux_monthly_average.txt | cut -b 1-25 >> solarradioflux.dat
$HOME/NINO/copyfilesall.sh solarradioflux.dat
