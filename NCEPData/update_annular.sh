#!/bin/sh
# AAO
cp monthly.aao.index.b79.current.ascii monthly.aao.index.b79.current.ascii.old
url=https://www.cpc.ncep.noaa.gov/products/precip/CWlink/daily_ao_index/aao/monthly.aao.index.b79.current.ascii
wget -q -N --no-check-certificate $url
[ ! -s monthly.aao.index.b79.current.ascii ] && echo "$0: daily_ao_index/aao/monthly.aao.index.b79.current.ascii has length zero" && exit -1
cat > cpc_aao.dat <<EOF
# CPC <a href="http://www.cpc.ncep.noaa.gov/products/precip/CWlink/daily_ao_index/aao/aao.shtml">AAO</a> index
# AAO [1] Antarctic Oscillation Index
# institution :: NOAA/NCEP/CPC
# source :: $url
# history :: downloaded on `date`
EOF
sed -e '/-0.99900E+34/d' monthly.aao.index.b79.current.ascii >> cpc_aao.dat

# AO
cp monthly.ao.index.b50.current.ascii monthly.ao.index.b50.current.ascii.old
url=https://www.cpc.ncep.noaa.gov/products/precip/CWlink/daily_ao_index/monthly.ao.index.b50.current.ascii
wget -q -N --no-check-certificate $url
[ ! -s monthly.ao.index.b50.current.ascii ] && echo "$0: monthly.ao.index.b50.current.ascii has length zero" && exit -1
cat > cpc_ao.dat <<EOF
# CPC <a href="http://www.cpc.ncep.noaa.gov/products/precip/CWlink/daily_ao_index/ao.shtml">AO</a> index
# AO [1] Arctic Oscillation Index
# institution :: NOAA/NCEP/CPC
# source :: $url
# history :: downloaded on `date`
EOF
sed -e '/-0.99900E+34/d' monthly.ao.index.b50.current.ascii >> cpc_ao.dat

# these two indices are not in standard Climate Explorer format:
# last line has spaces instead of -999.9 so is not read.
# However, they are not exposed in the UI.
# NAO
cp norm.nao.monthly.b5001.current.ascii.table norm.nao.monthly.b5001.current.ascii.table.old
url=https://www.cpc.ncep.noaa.gov/products/precip/CWlink/pna/norm.nao.monthly.b5001.current.ascii.table
wget -q -N --no-check-certificate $url
cat > cpc_nao2.dat <<EOF
# CPC <a href="http://www.cpc.ncep.noaa.gov/products/precip/CWlink/pna/nao.shtml">NAO</a> index
# NAO [1] North Atlantic Oscillation Index
# institution :: NOAA/NCEP/CPC
# source :: $url
# history :: downloaded on `date`
EOF
sed -e 's/-99.99/-999.9/g' norm.nao.monthly.b5001.current.ascii.table >> cpc_nao2.dat

# PNA
cp norm.pna.monthly.b5001.current.ascii.table norm.pna.monthly.b5001.current.ascii.table.old
url=https://www.cpc.ncep.noaa.gov/products/precip/CWlink/pna/norm.pna.monthly.b5001.current.ascii.table
wget -q -N --no-check-certificate $url
cat > cpc_pna2.dat <<EOF
# CPC <a href="http://www.cpc.ncep.noaa.gov/products/precip/CWlink/pna/pna.shtml">PNA</a> index
# PNA [1] Pacific North America Pattern
# institution :: NOAA/NCEP/CPC
# source :: $url
# history :: downloaded on `date`
EOF
sed -e 's/-9.99/-999.9/g' norm.pna.monthly.b5001.current.ascii.table >> cpc_pna2.dat

$HOME/NINO/copyfilesall.sh cpc_ao.dat cpc_aao.dat cpc_nao2.dat cpc_pna2.dat

