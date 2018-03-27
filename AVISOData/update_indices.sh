#!/bin/sh
base=ftp://ftp.aviso.altimetry.fr/pub/oceano/AVISO/indicators/msl
file=MSL_Serie_MERGED_Global_AVISO_GIA_Adjust_Filter2m.txt
wget -q -N $base/$file
make tenday2month
cat > ssh_aviso.dat <<EOF
# source :: https://www.aviso.altimetry.fr/en/data/products/ocean-indicators-products/mean-sea-level/products-images.html
# references :: http://www.aviso.altimetry.fr
# institution :: CLS
# contact :: aviso@altimetry.fr
# history :: retrieved `date`
EOF
./tenday2month $file >> ssh_aviso.dat
daily2longer ssh_aviso.dat 1 mean ssh_aviso.dat > ssh_aviso_annual.dat
$HOME/NINO/copyfilesall.sh  ssh_aviso.dat