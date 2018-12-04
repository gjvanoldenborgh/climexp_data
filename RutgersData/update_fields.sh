#!/bin/sh
force=""
[ -n "$1" ] && force=$1

usecdr=true
if [ usecdr = false ]; then

file=rutgers-monthly-snow.mtx
cp $file.gz $file.gz.old
wget -N --no-check-certificate --user=knmi https://climate.rutgers.edu/snowcover/files/$file.gz
cmp $file.gz $file.gz.old
if [ $? != 0 -o "$force" = force ]; then
    gunzip -c $file.gz > $file
    ./polar2grads
    grads2nc snow_rucl.ctl snow_rucl.nc
    ncatted -h -a institution,global,o,c,"Rutgers University/Climate Lab/Global Snow Lab" \
            -a source_url,global,c,c,"https://climate.rutgers.edu/snowcover/index.php" \
            snow_rucl.nc
    file=snow_rucl.nc
    . $HOME/climexp/add_climexp_url_field.cgi
    $HOME/NINO/copyfiles.sh snow_rucl.nc
fi

else

# new CDR files, interplate to lat/lon, daily, monthly.

base=https://www.ncei.noaa.gov/data/snow-cover-extent/access
curl $base/ > index.html
file=`fgrep nhsce_ index.html | sed -e 's/^.*href=\"//' -e 's/\".*$//'`
rm index.html
echo "CDR file is $file"

for oldfile in nhsce_*.nc; do
    if [ -f $oldfile -a $oldfile != $file ]; then
        rm $oldfile
    fi
done
wget -q -N --no-check-certificate $base/$file
if [ ! -s snow_rucl.nc -o snow_rucl.nc -ot $file -o "$force" = force ]; then
    cdo -r -f nc4 -z zip remapbil,snow_grid.nc $file snow_rucl_week.nc
    cdo -r -f nc4 -z zip intntime,7 snow_rucl_week.nc snow_rucl_day.nc
    # cdo monmean produces last months whenever there is 1 day of data...
    daily2longerfield snow_rucl_day.nc 12 mean minfac 80 add_persist snow_rucl.nc
    for file in snow_rucl.nc snow_rucl_day.nc; do
        # curiously, these are not in the 1m metadata of his CDR...
        ncatted -h -a references,global,a,c,"Robinson, David A., Estilow, Thomas W., and NOAA CDR Program (2012): NOAA Climate Data Record (CDR) of Northern Hemisphere (NH) Snow Cover Extent (SCE), Version 1. $name. NOAA National Centers for Environmental Information. doi:10.7289/V5N014G9" \
                -a doi,global,a,c,"doi:10.7289/V5N014G9" $file
        . $HOME/climexp/add_climexp_url_field.cgi
    done
    $HOME/NINO/copyfiles.sh snow_rucl.nc snow_rucl_day.nc
fi

fi