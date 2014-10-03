#!/bin/sh
wget -N http://iprc.soest.hawaii.edu/users/ykaji/monsoon/wnpmidx/data/wnpmidx.1948-2008.tar.gz
tar zxf wnpmidx.1948-2008.tar.gz
./txt2dat > wnpmidx.dat
$HOME/NINO/copyfiles.sh wnpmidx.dat
