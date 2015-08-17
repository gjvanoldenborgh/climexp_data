#!/bin/sh
get_index ersstv4.nc 90 100 -10 0 > seio_ersst.dat
get_index ersstv4.nc 40 80 -15 15 > wio_ersst.dat
normdiff wio_ersst.dat seio_ersst.dat none none > dmi_ersst.dat
