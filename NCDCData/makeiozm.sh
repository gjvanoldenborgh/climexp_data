#!/bin/sh
if [ -z "$version" ]; then
    echo "$0: error: version unset"
    exit
fi

get_index ersst${version}.nc 90 110 -10 0 | sed -e "s/spatial statistic of/SEIO index based on/" > aap.dat
plotdat anom 1982 2005 aap.dat | fgrep -v repeat > seio_ersst.dat
get_index ersst${version}.nc 50 70 -10 10 | sed -e "s/spatial statistic of/WTIO index based on/" > aap.dat
plotdat anom 1982 2005 aap.dat | fgrep -v repeat > wtio_ersst.dat
normdiff wtio_ersst.dat seio_ersst.dat none none | sed -e "s/Difference between wtio_ersst.dat and seio_ersst.dat/DMI based on NOAA ERSST$version/" > dmi_ersst.dat
