#!/bin/sh
debug=false
base=https://climate.rutgers.edu/snowcover/files/
ncfile=`curl -s https://www.ncei.noaa.gov/data/snow-cover-extent/access/ | fgrep nhsce | sed -e 's/^.*href=["]//' -e 's/.nc.*/.nc/'`
if [ "$debug" != true ]; then
    wget -q -N --no-check-certificate https://www.ncei.noaa.gov/data/snow-cover-extent/access/$ncfile
fi
for area in nh eurasia namerica namerica2
do
    case $area in
        nh) file=moncov.nhland.txt;name="Northern Hemisphere";;
        eurasia) file=moncov.eurasia.txt;name="Euarsia";;
        namerica) file=moncov.namgnld.txt;name="North America";;
        namerica2) file=moncov.nam.txt;name="North America without Greenland";;
    *) echo "error 76523569784"; exit -1;;
    esac

    if [ "$debug" != true ]; then
        wget -N --no-check-certificate $base/$file
    fi
    outfile=${area}_snow_km.dat

    cat <<EOF > $outfile
# $name snow cover from <a href="http://climate.rutgers.edu/snowcover/table_area.php?ui_set=2" target="_new">Rutgers University Global Snow Lab</a>
# snow_cover_extent [10^6 km2] GSL $name snow cover extent
# references :: Robinson, David A., Estilow, Thomas W., and NOAA CDR Program (2012): NOAA Climate Data Record (CDR) of Northern Hemisphere (NH) Snow Cover Extent (SCE), Version 1. $name. NOAA National Centers for Environmental Information. doi:10.7289/V5N014G9
# doi :: doi:10.7289/V5N014G9
# history :: retrieved `date`
EOF
    ncdump -h $ncfile \
        | fgrep -v '}' | fgrep -v geospatial | fgrep -v spatial_resolution | tr -d '[' \
        | sed -e '1,/global attributes/d' -e 's/[^:]*:/# /' -e 's/ = / :: /' -e 's/["]//g' -e 's/ ;//' >> $outfile
    cat $file >> $outfile
    scaleseries 0.000001 $outfile > ${area}_snow.dat
done
$HOME/NINO/copyfilesall.sh *_snow.dat
