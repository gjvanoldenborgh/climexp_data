#!/bin/sh
getit="wget -q --user-agent="" -N"
# GISS requires HTTP/1.1, which wget does not have at the server but curl does...
getit="curl -s -O -z"

# Volcanic AOD

base=http://data.giss.nasa.gov/modelforce/strataer
file=tau.line_2012.12.txt
$getit $file $base/$file
mv tau.line_2012.12.txt tau_line.txt
./saod2dat
$HOME/NINO/copyfilesall.sh saod*.dat

# GISTEMP

base=http://data.giss.nasa.gov/gistemp/tabledata_v3/
for type in Ts Ts+dSST
do
	for region in GLB NH SH 
	do
		file=$region.$type.txt
		cp $file $file.old
		$getit $file $base/$file
		[ ! -s $file ] && exit -1
		./txt2dat $region $type
		###echo region=$region,type=$type
		if [ $region = GLB -a $type = "Ts+dSST" ]; then
			file=giss_al_gl_m.dat
			echo "filteryearseries lo running-mean 4 $file > ${file%.dat}_4yrlo.dat"
			filteryearseries lo running-mean 4 $file > ${file%.dat}_4yrlo.dat
			file=giss_al_gl_a.dat
			filteryearseries lo running-mean 4 $file > ${file%.dat}_4yrlo.dat
		fi
	done
done
$HOME/NINO/copyfilesall.sh giss*.dat
