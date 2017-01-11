#!/bin/sh
cd $HOME/NINO/BMRCData/
[ -f rmm1rmm2.txt ] && mv rmm1rmm2.txt rmm1rmm2.txt.old
###curl -s http://cawcr.gov.au/bmrc/clfor/cfstaff/matw/maproom/RMM/RMM1RMM2.74toRealtime.txt > rmm1rmm2.txt
curl -s http://www.bom.gov.au/climate/mjo/graphics/rmm.74toRealtime.txt > rmm1rmm2.txt
if [ ! -s rmm1rmm2.txt ]
then
  echo "rmm1rmm2.txt too small: $c"
  rm rmm1rmm2.txt
  exit -1
fi
./rmm2dat
$HOME/NINO/copyfiles.sh rmm1.dat rmm2.dat
