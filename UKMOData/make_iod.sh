#!/bin/sh
get_index HadISST_sst.nc 90 110 -10 0 > aap.dat
plotdat anom 1982 2005 aap.dat | fgrep -v repeat > hadisst1_seio.dat
get_index HadISST_sst.nc 50 70 -10 10 > aap.dat
plotdat anom 1982 2005 aap.dat | fgrep -v repeat > hadisst1_wtio.dat
normdiff hadisst1_wtio.dat hadisst1_seio.dat none none > hadisst1_dmi.dat
