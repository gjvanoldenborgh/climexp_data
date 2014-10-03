#!/bin/sh
mv iers.data iers.data.old
url=http://data.iers.org/products/214/14443/orig/eopc04_08_IAU2000.62-now
wget -N $url
cp `basename $url` iers.data
cat > lod.dat << EOF
# LOD [s] lenth of day
# from <a href="http://www.iers.org/MainDisp.csl?pid=36-9" target="_new">IERS</a>
EOF
cat iers.data | cut -b 1-12,54-65 | egrep '^(19|20)' >> lod.dat
daily2longer lod.dat 12 mean > lod_12.dat
$HOME/NINO/copyfiles.sh lod.dat lod_12.dat
