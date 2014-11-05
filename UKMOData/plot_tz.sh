#!/bin/sh
for lag in -4 0 +4
do
    case $lag in
	-?) extra="AMO leading";;
	0) extra="";;
	+?) extra="AMOC lagging";;
	*) echo "error: unknown lag $lag"; exit -1;;
    esac
    file=regr_tz_amo_lag$lag
    grads -b -l -c 'run startup.gs' <<EOF
sdfopen $file.nc
sdfopen mean_tz.nc
set lev 0 3000
danod regr shaded 0 0 -1 1
cbarn
set gxout contour
set cint 2
set lev 3000 0
set yflip off
d mean.2-273.15
draw title regr Tzonal on AMO, 7-yr mean, lag ${lag}yr $extra
print $file.eps
quit
EOF
done
