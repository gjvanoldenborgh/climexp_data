#!/bin/sh
# The North Pacific Index (should compute it myself, really...)
#
cp indices.data.html indices.data.html.old
wget -N http://www.cgd.ucar.edu/cas/jhurrell/indices.data.html
mv np.dat np.dat.old
cat > np.dat <<EOF
# The NP Index is the area-weighted sea level pressure over the region 30N-65N, 160E-140W, available since 1899.
# NP Index Data provided by the Climate Analysis Section, NCAR, Boulder, USA, Trenberth and Hurrell (1994).
# <a href="http://www.cgd.ucar.edu/cas/jhurrell/indices.data.html#npmon">source</a>
EOF
sed -e '1,/Monthly North Pacific Index/d' indices.data.html \
| tail -n +9 \
| sed -e '/pre/,$d' \
| sed -e 's/ -99./-999.9/g' \
>> np.dat

$HOME/NINO/copyfiles.sh np.dat
