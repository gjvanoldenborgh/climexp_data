#!/bin/sh
# compute land & sea separately
line=`describefield giss_temp_both_1200.nc 2>&1 | fgrep Monthly`
#echo "line=$line"
start=`echo $line | awk '{print $5}'`
#echo "start=$start"
nt=`echo $line | awk '{print $8}' | tr '(' ' '`
#echo "nt=$nt"
grads=`which grads`
ppc=`file $grads | fgrep -c ppc`
if [ $ppc = 1 ]; then
  endian=BIG_ENDIAN
else
  endian=LITTLE_ENDIAN
fi
for type in land sea
do
    case $type in
	land) mask="tmp2m.2(t=1))";;
	sea) mask="1-const(tmp2m.2(t=1),0,-u))"
    esac
    cat > giss_$type.ctl <<EOF
DSET ^giss_$type.grd
TITLE GISS $type averaged temperature
OPTIONS $endian
UNDEF -0.999E+09
XDEF 1 LINEAR 0 1
YDEF 1 LINEAR 0 1
ZDEF 1 LINEAR 0 1
TDEF $nt LINEAR 15$start 1MO
VARS 1
Ta 0 99 $type mean temperature anomaly [K]
ENDVARS 
EOF
    grads -b -l > /tmp/grads.$type.log <<EOF
sdfopen giss_temp_both_1200.nc
sdfopen $HOME/climexp_data/NCEPData/ghcn_cams_10.nc
set t 1 last
set gxout fwrite
set fwrite giss_$type.grd
d aave(maskout(tempanomaly,$mask,lon=0,lon=360,lat=-90,lat=90)
disable fwrite
quit
EOF
    netcdf2ascii giss_$type.ctl > giss_$type.dat
    daily2longer giss_$type.dat 1 mean > giss_${type}_mean1.dat
    $HOME/NINO/copyfilesall.sh giss_$type.dat giss_${type}_mean1.dat
    plotdat giss_${type}_mean1.dat > giss_${type}_mean1.txt
done
plotdat giss_ts_gl_a.dat > giss.dat
