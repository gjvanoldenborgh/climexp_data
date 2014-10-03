#!/bin/sh
mv t.1948_cur t.1948_cur.old
wget ftp://ftp.cpc.ncep.noaa.gov/wd51yf/global_monthly/t.1948_cur
cmp t.1948_cur t.1948_cur.old
#if [ $? ]; then
#  ./huug2grads
#fi
