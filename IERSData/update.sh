#!/bin/sh
mv iers.data iers.data.old
url=https://datacenter.iers.org/eop/-/somos/5Rgv/latest/213
wget -N --no-check-certificate $url
cp `basename $url` iers.data
cat > lod.dat << EOF
# LOD [s] length of day
# from <a href="http://www.iers.org/IERS/EN/DataProducts/EarthOrientationData/eop.html" target="_new">IERS</a>
# institution :: IERS Earth Orientation Centre
# contact :: services.iers@obspm.fr
# title :: EOP 08 C04 series for 1962-2018 (IAU2000)
# source :: http://www.iers.org/IERS/EN/DataProducts/EarthOrientationData/eop.html
# source_url :: https://datacenter.iers.org/eop/-/somos/5Rgv/latest/213
# documentation :: ftp://hpiers.obspm.fr/iers/eop/eopc04_08/C04.guide.pdf
# history :: retrieved `date`
# climexp_url :: https://climexp.knmi.nl/getindices.cgi?IERSData/lod
EOF
cat iers.data | cut -b 1-12,54-65 | egrep '^(19|20)' >> lod.dat
daily2longer lod.dat 12 mean | sed -e 's@/lod@/lod_12@' > lod_12.dat
$HOME/NINO/copyfiles.sh lod.dat lod_12.dat
