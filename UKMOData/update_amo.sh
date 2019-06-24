#!/bin/sh
export LANG=C

# 1. Definition of van Oldenborgh et al, OS, 2009

[ -z "$version" ] && echo "$0: error: please define version $version" && exit -1
ncfile=HadSST.${version}_median.nc
[ ! -s $ncfile ] && echo "$0: error: cannot find $ncfile" && exit -1
get_index $ncfile -75 -7 25 60 > hadsst_natl.dat
correlate hadsst_natl.dat file hadcrut4_ns_avg.dat mon 1:12 plot aap.txt
a=`awk '{print -$10}' aap.txt | tr '\n' ':'`
echo "$a"
if [ ${a#0:} != $a ]; then
    echo "Error in awk, a=$a"
    exit -1
fi
export FORM_a1=1
export FORM_a2=$a
gen_time 1700 2200 12 > dummy.12.dat
addseries dummy.12.dat file hadsst_natl.dat file hadcrut4_ns_avg.dat mon 1:12 plot aap.dat > /tmp/addseries.log
file=`tail -1 /tmp/addseries.log`
normdiff $file null none none > aap.dat
cat > amo_hadsst.dat <<EOF
# AMO index SST 25-60N, 7-75W minus regression on global mean temperature
# as in <a href="http://www.ocean-sci.net/5/293/2009/os-5-293-2009.html">van Oldenborgh et al 2009</a>
# based on HadSST $version
# reference :: van Oldenborgh, G. J., te Raa, L. A., Dijkstra, H. A., and Philip, S. Y., 2009: Frequency- or amplitude-dependent effects of the Atlantic meridional overturning on the tropical Pacific Ocean, Ocean Sci., 5, 293-301, https://doi.org/10.5194/os-5-293-2009
# AMO [K] Atlantic Multidecadal Variability index
EOF
fgrep ' :: ' aap.dat >> amo_hadsst.dat
fgrep -v '#' aap.dat >> amo_hadsst.dat
rm $file aap.dat
$HOME/NINO/copyfiles.sh amo_hadsst.dat

# 2. Defnbition of Trenberth & Shea 2006

get_index $ncfile -80 0 0 60 > hadsst_0-60N_0-80W.dat
get_index $ncfile 0 360 -60 60 > hadsst_60S-60N.dat
cat > amo_hadsst_ts.dat <<EOF
# AMO index SST EQ-60N, 0-80W minus SST 60S-60N
# as in <a href="http://onlinelibrary.wiley.com/doi/10.1029/2006GL026894/full">Trenberth and Shea 2006</a>
# based on HadSST ${version}
# reference :: K. E. Trenberth, D. J. Shea, 2006: Atlantic hurricanes and natural variability in 2005. Geophys. Res. Lett., 33, L12704, doi:10.1029/2006GL026894
# AMO [C] Atlantic Multidecadal Variability index
EOF
normdiff hadsst_0-60N_0-80W.dat hadsst_60S-60N.dat none none > aap.dat
fgrep ' :: ' aap.dat >> amo_hadsst_ts.dat
egrep -v '^#' aap.dat >> amo_hadsst_ts.dat
$HOME/NINO/copyfiles.sh amo_hadsst_ts.dat
