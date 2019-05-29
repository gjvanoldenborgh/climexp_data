#!/bin/bash
for levmax in 250 1000
do
    case $levmax in
	1000) ext="";;
	250) ext=_250;;
	*) echo "errorbhguyts31"; exit -1;;
    esac

for field in sigma # stabi temp salt
do
    case $field in
	temp) name=temperature;cmax=0.025;;
	salt) name=salinity;cmax=0.0025;;
	stabi) name=stability;cmax=0.0005;;
	sigma) name=stability;cmax=0.0025;;
	*) echo "error bhuiu2635tgyukgjbcdh"; exit -1
    esac

    for yrbeg in 1985 # 1975 1980 1985 1990
    do
	grads -b -l -c 'run startup.gs' << EOF
open trend_${field}_zonalmean_$yrbeg
open mean_${field}_zonalmean_$yrbeg
set lev 0 $levmax
set lat -80 -30
set yflip
danod regr.1 shaded 0 0 -$cmax $cmax
cbarn
set gxout contour
set clab off
d mean.2-273.15
draw title ${name} trend ${yrbeg}-2009
print trend_${field}_zonalmean_${yrbeg}$ext.eps
quit
EOF
	for mo in 3 6 9 12
	do
	    case $mo in
		3) season=autumn;t1=4;t2=5;;
		6) season=winter;t1=7;t2=8;;
		9) season=spring;t1=10;t2=11;;
		12) season=summer;t1=1;t2=2;;
	    esac
	    grads -b -l -c 'run startup.gs' << EOF
open trend_${field}_zonalmean_$yrbeg
open mean_${field}_zonalmean_$yrbeg
set lev 0 $levmax
set lat -80 -30
set yflip
danod (regr.1(t=$((t+1)))+regr.1(t=$((t1+1)))+regr.1(t=$((t2+1))))/3 shaded 0 0 -$cmax $cmax
cbarn
set gxout contour
set clab off
d (mean.2(t=$((t+1)))+mean.2(t=$(($t1+1)))+mean.2(t=$(($t2+1))))-273.15
draw title ${name} trend $season ${yrbeg}-2009
print trend_${field}_zonalmean_${season}_${yrbeg}$ext.eps
quit
EOF

	done
    done
done
done
