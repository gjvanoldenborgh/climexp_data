#!/bin/sh
base=http://www-users.york.ac.uk/~kdc3/papers/coverage2013
for file in had4_krig_v2_0_0.txt
do
    wget -N -q $base/$file
    f=${file%.txt}.dat
    cat > $f <<EOF
# <a href="http://www-users.york.ac.uk/~kdc3/papers/coverage2013/series.html">Cowtan and Way</a> global mean temperature, HadCRUT4 in-filled with kriging.
# Tglobal [K] global mean T2m/SST anomalies relative to 1961-1990
EOF
    cut -b 1-17 $file >> $f
done
$HOME/NINO/copyfilesall.sh had4*.dat
