#!/bin/sh
force=""
[ -n "$1" ] && force=$1
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
