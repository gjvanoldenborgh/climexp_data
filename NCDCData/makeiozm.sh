#!/bin/sh
get_index ersstv4.nc 90 110 -10 0 > aap.dat
plotdat anom 1982 2005 aap.dat | fgrep -v repeat > seio_ersst.dat
get_index ersstv4.nc 50 70 -10 10 > aap.dat
plotdat anom 1982 2005 aap.dat | fgrep -v repeat > wtio_ersst.dat
normdiff wtio_ersst.dat seio_ersst.dat none none > dmi_ersst.dat
