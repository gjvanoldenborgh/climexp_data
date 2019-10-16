#!/bin/sh
###getit="wget -q --user-agent="" -N"
# GISS requires HTTP/1.1, which wget does not have at the server but curl does...
getit="wget --no-check-certificate -N -q "

# GISTEMP

make txt2dat
base=https://data.giss.nasa.gov/gistemp/tabledata_v4/
for type in Ts Ts+dSST
do
	for region in GLB NH SH 
	do
		file=$region.$type.txt
		mv $file $file.old
		echo $getit $base/$file
		$getit $base/$file
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
echo "2040 1.17" >> ${file%m.dat}a_4yrlo.dat
echo "2045 1.27" >> ${file%m.dat}a_4yrlo.dat
echo "2065 1.67" >> ${file%m.dat}a_4yrlo.dat
echo "2070 1.77" >> ${file%m.dat}a_4yrlo.dat
echo "2100 2.67" >> ${file%m.dat}a_4yrlo.dat
echo "2105 2.77" >> ${file%m.dat}a_4yrlo.dat
echo "2150 3.67" >> ${file%m.dat}a_4yrlo.dat
echo "2155 3.77" >> ${file%m.dat}a_4yrlo.dat
echo "# the last eight values represent conventions for 1.5, 2.0, 3.0 and 4.0 degree worlds relative to pre-industrial and 1880-1900" >> ${file%m.dat}a_4yrlo.dat
$HOME/NINO/copyfilesall.sh giss*.dat

# Volcanic AOD

base=https://data.giss.nasa.gov/modelforce/strataer
file=tau.line_2012.12.txt
$getit $base/$file
mv tau.line_2012.12.txt tau_line.txt
if [ ! -x sao2dat ]; then
    gfortran -o saod2dat saod2dat.f90
fi
./saod2dat
$HOME/NINO/copyfilesall.sh saod*.dat
