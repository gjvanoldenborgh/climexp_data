#!/bin/sh
yr=`date -d "last month" +%Y`
mo=`date -d "last month" +%m`

# Trenberth monthly mean SLP (ds010.1)
wget --no-check-certificate --save-cookies cookie_file --post-data="email=oldenborgh@knmi.nl&passwd=rEjESwPQ&action=login" https://rda.ucar.edu/cgi-bin/login

set -x
wget --no-check-certificate --load-cookies cookie_file -O ds010_1.ascii.gz http://rda.ucar.edu/cgi-bin/dattore/subgrid\?sd=189901\&ed=$yr$mo\&of=ascii\&c=gz\&t=monthly\&d=010.1\&i=molydata.bin\&if=slp
c=`file ds010_1.ascii.gz | fgrep -c zip`
if [ $c != 1 ]; then
    echo "$0: error: something went wrong"
    exit -1
fi
cp ds010_1.ascii ds010_1.ascii.old
gunzip -c ds010_1.ascii.gz > ds010_1.ascii
cmp ds010_1.ascii ds010_1.ascii.old
if [ $? != 0 ]; then
  make ascii2dat
  ./ascii2dat
  $HOME/NINO/copyfiles.sh ds010_1.???
  ./make_snao.sh
fi
