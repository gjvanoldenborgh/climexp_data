#!/bin/sh
# The North Pacific Index (should compute it myself, really...)
#
cp indices.data.html indices.data.html.old
wget -N --no-check-certificate https://climatedataguide.ucar.edu/sites/default/files/npindex_monthly.txt
mv np.dat np.dat.old
cat > np.dat <<EOF
# The NP Index is the area-weighted sea level pressure over the region 30N-65N, 160E-140W, available since 1899.
# NP Index Data provided by the Climate Analysis Section, NCAR, Boulder, USA, Trenberth and Hurrell (1994).
# <a href="http://climatedataguide.ucar.edu/guidance/north-pacific-index-npi-trenberth-and-hurrell-monthly-and-winter">source</a>
# NPI [hPa] North Pacific Index
# institution :: 
EOF
tail -n +2 npindex_monthly.txt | sed -e 's/ -999.00/-999.9/g' >> np.dat

$HOME/NINO/copyfiles.sh np.dat
