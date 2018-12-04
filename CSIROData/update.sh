#!/bin/sh
patchseries ssh_church.dat ../AVISOData/ssh_aviso_annual.dat bias > ssh_church_extended.dat
$HOME/NINO/copyfilesall.sh  ssh_church_extended.dat
