#!/bin/bash
source_url=ftp://ftp.seismo.nrcan.gc.ca/spaceweather/solar_flux/monthly_averages/solflux_monthly_average.txt
wget -q -N $source_url
cat > solarradioflux_new.dat <<EOF
# Observed solar radio flux at 10.7cm from <a href="http://www.spaceweather.ca/sx-eng.php">Space Weather Canada</a>
# F10.7 [sfu] 10.7cm flux density
# institution :: NRC-CNRC Canada
# references :: https://www.spaceweather.gc.ca/solarflux/sx-3-en.php
# source_url :: $source_url
# contact :: ken.tapping@nrc-cnrc.gc.ca
# history :: retrieved `date`
# climexp_url :: http://climexp.knmi.nl/getinidices.cgi?solarradioflux
EOF
tail -n +3 solflux_monthly_average.txt | fgrep -v 9325021.54 | cut -b 1-25 >> solarradioflux_new.dat 
patchseries solarradioflux_new.dat solarradioflux_org.dat > solarradioflux.dat
$HOME/NINO/copyfilesall.sh solarradioflux.dat
