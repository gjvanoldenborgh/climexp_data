#!/bin/sh
get_index ersstv4.nc 90 100 -28 -18 > esiod_ersst.dat
get_index ersstv4.nc 55 65 -37 -27 > wsiod_ersst.dat
normdiff wsiod_ersst.dat esiod_ersst.dat none monthly > siod_ersst.dat
