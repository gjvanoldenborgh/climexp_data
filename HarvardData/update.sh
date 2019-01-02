#!/bin/sh
patchseries ssh_hay.dat ../AVISOData/ssh_aviso_annual.dat bias > ssh_hay_extended.dat
$HOME/NINO/copyfilesall.sh  ssh_hay_extended.dat
