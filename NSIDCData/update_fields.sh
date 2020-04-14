#!/bin/bash

# snow

if [ "$downloadnsidcsnow" = true ]; then

docs=http://nsidc.org/data/docs/daac/nise1_nise.gd.html
base=ftp://n4ftl01u.ecs.nasa.gov/SAN/OTHR/NISE.00

echo "DEBUG: downloading disabled"
###wget -r -o nise2.log -N ${base}2
###wget -r -o nise4.log -N ${base}4

yr=1995
mo=5
dy=4
ok=ok
timestep=-1
while [ $ok = ok ]
do
    timestep=$((timestep+1))
    if [ $mo -lt 10 ]; then
	mm=0$mo
    else
	mm=$mo
    fi
    if [ $dy -lt 10 ]; then
	dd=0$dy
    else
	dd=$dy
    fi
    if [ $yr$mm$dd -lt 20090911 ]; then
	version=2
	subversion=13
    else
	version=4
	subversion=17
    fi
    dir=n4ftl01u.ecs.nasa.gov/SAN/OTHR/NISE.00$version/$yr.$mm.$dd
    file=NISE_SSMIF${subversion}_$yr$mm$dd
    hdf_ncdump $dir/$file.HDFEOS > $file.cdl
    sed -e "s/TIMESTEP/$timestep/" axes.inc > axes.now
    sed -e "s/YDim:Northern Hemisphere/y1/" -e "s/XDim:Northern Hemisphere/x1/" \
	-e "s/YDim:Southern Hemisphere/y2/" -e "s/XDim:Southern Hemisphere/x2/" \
	-e "s/Extent(y1/Extent1(y1/" -e  "s/Extent(y2/Extent2(y1/" \
	-e "s/Age(y1/Age1(y1/" -e  "s/Age(y2/Age2(y1/" \
	-e "1,500s/Extent /Extent1 /" -e "s/Extent /Extent2 /" \
	-e "1,50000s/Age /Age1 /" -e "s/Age /Age2 /" \
	-e "/dimensions:/r dims.inc" \
	-e "/variables:/r vars.inc" \
	-e "/data:/r axes.now" \
	$file.cdl > $file.edited.cdl
###	-e "s/ 0,/ 0@,/g" -e "s/ 10[134],/ 1@,/g" -e "s/ [-0-9]*,/ -1@,/g" \
###	-e 's/@,/,/g' \
    /usr/bin/ncgen -o $file.nc  $file.edited.cdl
    ncatted -a _FillValue,Extent1,c,b,-1 -a _FillValue,Extent2,c,b,-1 $file.nc
    rm $file.cdl $file.edited.cdl

    dy=$((dy+1))
    case $mo in
	1|3|5|7|8|10|12) dpm=31;;
	4|6|9|11) dpm=30;;
	2) if [ $((yr/4)) = $yr ]; then
            dpm=29
            else
	    dpm=28
            fi;;
    esac
    if [ $dy -gt $dpm ]; then
	dy=$((dy-dpm))
	mo=$((mo+1))
exit
    fi
    if [ $mo -gt 12 ]; then
	mo=$((mo-12))
	yr=$((yr+1))
    fi
done

echo "DEBUG: nothing else"
exit #DEBUG

fi

# sea ice

base=ftp://sidads.colorado.edu/pub/DATASETS
subdir=nsidc0051_gsfc_nasateam_seaice

for version in final-gsfc # preliminary
do
  	for region in north south
  	do
    	wget -N $base/$subdir/$version/$region/monthly/\*.bin
  	done
done

# get last month with monthly data
yr=2018
m=1
mo=01
file=`ls -t nt_${yr}${mo}_*_n.bin | head -1`
while [ -n "$file" -a -s "$file" ]; do
    ((m++))
    if [ $m -gt 12 ]; then
        m=1
        ((yr++))
    fi
    mo=`printf %02i $m`
    file=`ls -t nt_${yr}${mo}_*_n.bin | head -1`
done
echo "starting daily downloads from $yr$mo"

# get daily data
wget="wget -N -q --no-check-certificate --load-cookies ~/.urs_cookies --save-cookies ~/.urs_cookies --auth-no-challenge=on --keep-session-cookies"
base=https://n5eil01u.ecs.nsidc.org/PM/NSIDC-0081.001
file=$0 # something that exists
d=0
while [ -s $file ]; do
    ((d++))
    case $m in
        1|3|5|7|8|10|12) dpm=31;;
        4|6|9|11) dpm=30;;
        2)  if [ $(( 4*(yr/4) )) = $yr ]; then
                dpm=29
            else
                dpm=28
            fi;;
        *) echo "$0: error gyuotu73o88"; exit -1;;
    esac
    if [ $d -gt $dpm ]; then
        d=1
        ((m++))
    fi
    if [ $m -gt 12 ]; then
        m=1
        ((yr++))
    fi
    mo=`printf %02i $m`
    dy=`printf %02i $d`
    subdir=${yr}.${mo}.${dy}
    file=nt_${yr}${mo}${dy}_f18_nrt_n.bin
    echo "$wget $base/$subdir/$file"
    $wget $base/$subdir/$file
    file=nt_${yr}${mo}${dy}_f18_nrt_s.bin
    echo "$wget $base/$subdir/$file"
    $wget $base/$subdir/$file
done

###subdir=nsidc0081_nrt_nasateam_seaice
###for region in north south
###do
###  wget -N $base/$subdir/$region/\*.bin
###done

make day2mon
./day2mon
make polar2grads
./polar2grads
for pole in n s; do
    grads2nc conc_$pole.ctl conc_$pole.nc
    file=conc_$pole.nc
    ncatted -h -a institution,global,o,c,"NSIDC" \
            -a source_url,global,c,c,"http://nsidc.org/data/nsidc-0051.html" \
            -a reference,global,c,c,"Cavalieri, D. J., C. L. Parkinson, P. Gloersen, and H. J. Zwally. 1996, updated yearly. Sea Ice Concentrations from Nimbus-7 SMMR and DMSP SSM/I-SSMIS Passive Microwave Data, Version 1. Boulder, Colorado USA. NASA National Snow and Ice Data Center Distributed Active Archive Center. doi: http://dx.doi.org/10.5067/8GQ8LZQVL0VL. Accessed `date`" \
                $file
    . $HOME/climexp/add_climexp_url_field.cgi
done
$HOME/NINO/copyfiles.sh conc_?.nc
