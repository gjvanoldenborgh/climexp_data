#!/bin/sh
get_index hadisst1.ctl 90 100 -28 -18 > hadisst1_esiod.dat
get_index hadisst1.ctl 55 65 -37 -27 > hadisst1_wsiod.dat
normdiff hadisst1_wsiod.dat hadisst1_esiod.dat none none > aap.dat
scaleseries 1.5 aap.dat > hadisst1_siod.dat
