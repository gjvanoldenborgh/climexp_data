#!/bin/sh
patchseries ssh_dangendorf_mo.dat ../AVISOData/ssh_aviso.dat bias > ssh_dangendorf_mo_extended.dat
patchseries ssh_dangendorf.dat ../AVISOData/ssh_aviso_annual.dat bias > ssh_dangendorf_extended.dat
$HOME/NINO/copyfilesall.sh ssh_dangendorf_extended.dat ssh_dangendorf_mo_extended.dat
