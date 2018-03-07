#!/bin/sh
wget -q -N ftp://ftp.geolab.nrcan.gc.ca/data/solar_flux/monthly_averages/solflux_monthly_average.txt
cat  > solarradioflux.dat <<EOF
# Observed solar radio flux at 10.7cm from <a href="http://www.spaceweather.ca/sx-eng.php">Space Weather Canada</a>
# F10.7 [sfu] 10.7cm flux density
# institution :: NRC-GNRC Canada
# references :: https://www.nrc-cnrc.gc.ca/eng/solutions/advisory/solar_weather_monitoring.html
# contact :: ken.tapping@nrc-cnrc.gc.ca
# history :: retrieved `date`
# climexp_url :: http://climexp.knmi.nl/getinidices.cgi?solarradioflux
EOF
tail -n +3 solflux_monthly_average.txt | cut -b 1-25 >> solarradioflux.dat
$HOME/NINO/copyfilesall.sh solarradioflux.dat
