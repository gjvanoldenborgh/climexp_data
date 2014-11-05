#!/bin/sh
get_index hadisst1.ctl 90 100 -10 0 > hadisst1_seio.dat
get_index hadisst1.ctl 40 80 -15 15 > hadisst1_wio.dat
normdiff hadisst1_wio.dat hadisst1_seio.dat none none > hadisst1_dmi.dat
