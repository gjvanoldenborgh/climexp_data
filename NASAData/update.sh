#!/bin/sh
###getit="wget -q --user-agent="" -N"
# GISS requires HTTP/1.1, which wget does not have at the server but curl does...
getit="curl -O -z"

# GISTEMP

base=http://data.giss.nasa.gov/gistemp/tabledata_v3/
for type in Ts Ts+dSST
do
	for region in GLB NH SH 
	do
		file=$region.$type.txt
		cp $file $file.old
		echo $getit $file $base/$file
		$getit $file $base/$file
		[ ! -s $file ] && echo "problems downloading $base/$file" && exit -1
		c=`file $file | fgrep -c HTML`
		[ $c != 0 ] && echo "problems downloading $base/$file" && exit -1
		./txt2dat $region $type
		###echo region=$region,type=$type
	done
done
for region in gl nh sh
do
    daily2longer giss_al_${region}_m.dat 1 mean add_pers > giss_al_${region}_a.dat
done
file=giss_al_gl_m.dat
echo "filteryearseries lo running-mean 4 $file > ${file%.dat}_4yrlo.dat"
filteryearseries lo running-mean 4 $file minfac 25 minfacsum 25 > ${file%.dat}_4yrlo.dat
daily2longer ${file%.dat}_4yrlo.dat 1 mean minfac 25 > ${file%m.dat}a_4yrlo.dat
$HOME/NINO/copyfilesall.sh giss*.dat

# Volcanic AOD

base=http://data.giss.nasa.gov/modelforce/strataer
file=tau.line_2012.12.txt
wget -N $file $base/$file
mv tau.line_2012.12.txt tau_line.txt
./saod2dat
$HOME/NINO/copyfilesall.sh saod*.dat
