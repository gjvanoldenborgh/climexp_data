#!/bin/sh
wget -q -N http://www.o3d.org/npgo/npgo.php
./txt2dat > npgo.dat
$HOME/NINO/copyfilesall.sh npgo.dat
