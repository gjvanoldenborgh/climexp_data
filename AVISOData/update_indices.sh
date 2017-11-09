#!/bin/sh
base=ftp://ftp.aviso.altimetry.fr/pub/oceano/AVISO/indicators/msl
file=MSL_Serie_MERGED_Global_AVISO_GIA_Adjust_Filter2m.txt
wget -q -N $base/$file
make tenday2month
./tenday2month $file > ssh_aviso.dat
daily2longer ssh_aviso.dat 1 mean ssh_aviso.dat > ssh_aviso_annual.dat
$HOME/NINO/copyfilesall.sh  ssh_aviso.dat