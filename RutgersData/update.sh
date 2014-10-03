#!/bin/sh
base=http://climate.rutgers.edu/snowcover/files/
for area in nh eurasia namerica namerica2
do
  case $area in
  nh) file=moncov.nhland.txt;name="Northern Hemisphere";;
  eurasia) file=moncov.eurasia.txt;name="Euarsia";;
  namerica) file=moncov.namgnld.txt;name="North America";;
  namerica2) file=moncov.nam.txt;name="North America without Greenland";;
  *) echo "error 76523569784"; exit -1;;
  esac

  wget -N $base/$file
  
  outfile=aap.dat

  cat <<EOF > $outfile
# $name snow cover from <a href="http://climate.rutgers.edu/snowcover/table_area.php?ui_set=2" target="_new">Rutgers University Global Snow Lab</a>
# snowcover [10^6 km2]
EOF
  cat $file >> $outfile
  scaleseries 0.000001 $outfile > ${area}_snow.dat
done
$HOME/NINO/copyfilesall.sh *_snow.dat
