#!/bin/sh
FC=pgf90
$FC -o current2dat current2dat.f ~/NINO/Fortran/$PVM_ARCH/climexp.a
cp fluxtablerolling.text fluxtablerolling.text.old
wget -q -N ftp://lynx.drao.nrc.ca/pub/solar/FLUX_DATA/fluxtablerolling.text
./current2dat
$HOME/NINO/copyfilesall.sh solarradioflux.dat
