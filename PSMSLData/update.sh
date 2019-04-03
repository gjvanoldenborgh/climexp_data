#!/bin/sh
# upxdated to the new format (2019)

cp nucat.dat nucat.dat.old
wget -q -N --no-check-certificate https://www.psmsl.org/data/obtaining/rlr.monthly.data/rlr_monthly.zip
wget -q -N --no-check-certificate https://www.psmsl.org/data/obtaining/nucat.dat
###wget -q -N --no-check-certificate https://www.psmsl.org/data/obtaining/catalogue.dat
wget -q -N --no-check-certificate https://www.psmsl.org/data/obtaining/psmsl.hel

exit

make dat2mydat
mv psmsl.mydat psmsl.mydat.old
./dat2mydat

nrec_slv=`wc -l < psmsl.mydat`
nstat_slv=`tail -1 psmsl.mydat | cut -b 1-6`
sed -e "s/NREC_SLV/$nrec_slv/" \
 -e "s/NSTAT_SLV/$nstat_slv/" \
  support_in.f > support.f
make getsealev 

$HOME/NINO/copyfiles.sh nucat.dat psmsl.mydat
scp getsealev bhlclim:climexp/bin/

