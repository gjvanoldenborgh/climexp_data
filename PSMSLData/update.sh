#!/bin/sh
# upxdated to the new format (2019)

cp nucat.dat nucat.dat.old
wget -q -N --no-check-certificate https://www.psmsl.org/data/obtaining/rlr.monthly.data/rlr_monthly.zip
wget -q -N --no-check-certificate https://www.psmsl.org/data/obtaining/nucat.dat
###wget -q -N --no-check-certificate https://www.psmsl.org/data/obtaining/catalogue.dat
wget -q -N --no-check-certificate https://www.psmsl.org/data/obtaining/psmsl.hel

rm -rf rlr_monthly
unzip rlr_monthly.zip
make getsealev

###$HOME/NINO/copyfiles.sh nucat.dat
###scp getsealev bhlclim:climexp/bin/

