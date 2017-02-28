#!/bin/sh
mv iers.data iers.data.old
url=http://datacenter.iers.org/eop/-/somos/5Rgv/latest/213
wget -N --no-check-certificate $url
cp `basename $url` iers.data
cat > lod.dat << EOF
# LOD [s] lenth of day
# from <a href="http://www.iers.org/IERS/EN/DataProducts/EarthOrientationData/eop.html" target="_new">IERS</a>
EOF
cat iers.data | cut -b 1-12,54-65 | egrep '^(19|20)' >> lod.dat
daily2longer lod.dat 12 mean > lod_12.dat
$HOME/NINO/copyfiles.sh lod.dat lod_12.dat
