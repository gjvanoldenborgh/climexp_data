#!/bin/sh
wget -q -N http://www.o3d.org/npgo/npgo.php
[ ! -s txt2dat ] && gfortran -o txt2dat txt2dat.f90
./txt2dat > npgo.dat
$HOME/NINO/copyfilesall.sh npgo.dat
