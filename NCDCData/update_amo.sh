#!/bin/sh

# 1. Definition of van Oldenborgh et al, OS, 2009

get_index ersstv4.nc -75 -7 25 60 > ersst_natl.dat
correlate ersst_natl.dat file ../NASAData/giss_al_gl_m.dat  mon 1:12 plot aap.dat
a=`awk '{print -$10}' aap.dat | tr '\n' ':'`
export FORM_a1=1
export FORM_a2=$a
gen_time 1700 2200 12 > dummy.12.dat
addseries dummy.12.dat file ersst_natl.dat file ../NASAData/giss_al_gl_m.dat  mon 1:12 plot aap.dat > /tmp/addseries.log
file=`tail -1 /tmp/addseries.log`
normdiff $file null none none > aap.dat
cat > amo_ersst.dat <<EOF
# AMO index SST 25-60N, 7-75W minus regression on global mean temperature
# as in <a haref="http://www.ocean-sci.net/5/293/2009/os-5-293-2009.html">van Oldenborgh et al 2009</a>
# based on ERSST v3b from NCDC
# AMO [C] SST
EOF
fgrep -v '#' aap.dat >> amo_ersst.dat
rm $file aap.dat
$HOME/NINO/copyfiles.sh amo_ersst.dat

# 2. Definition of Trenberth & Shea 2006

get_index ersstv4.nc -80 0 0 60 > ersst_0-60N_0-80W.dat
get_index ersstv4.nc 0 360 -60 60 > ersst_60S-60N.dat
cat > amo_ersst_ts.dat <<EOF
# AMO index SST EQ-60N, 0-80W minus SST 60S-60N
# as in <a href="http://www.agu.org/pubs/crossref/2006/2006GL026894.shtml">Trenberth and Shea 2006</a>
# based on ERSST v3b from NCDC
# AMO [C] SST
EOF
normdiff ersst_0-60N_0-80W.dat ersst_60S-60N.dat none none | egrep -v '^#' >> amo_ersst_ts.dat
$HOME/NINO/copyfiles.sh amo_ersst_ts.dat

# 3. Adjusted definition of Trenberth & Shea 2006

get_index ersstv4.nc -80 0 30 60 > ersst_30-60N_0-80W.dat
cat > amo30_ersst_ts.dat <<EOF
# AMO index SST 30-60N, 0-80W minus SST 60S-60N
# based on ERSST v3b from NCDC
# AMO30 [C] SST
EOF
normdiff ersst_30-60N_0-80W.dat ersst_60S-60N.dat none none | egrep -v '^#' >> amo30_ersst_ts.dat
$HOME/NINO/copyfiles.sh amo30_ersst_ts.dat
