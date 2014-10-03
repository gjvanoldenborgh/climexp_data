#!/bin/sh
wget -N ftp://ftp.pmodwrc.ch/pub/data/irradiance/composite/DataPlots/composite_d41_64_*.dat
file=`ls -t composite_d41_64_*.dat | head -1`
cat > tsi_daily.dat <<EOF
# Observed solar constant reconstructed from satellite observations.
# Please cite C.Fr\"ohlich, 2000, "Observations of Irradiance Variations, Space Science Rev., 94, pp. 15-24.
# <a href="http://www.pmodwrc.ch/pmod.php?topic=tsi/composite/SolarConstant">source</a>
# TSI [W/m2] total solar irradiance averaged over one day
EOF
tail -n +2 $file | egrep -v '^;' | awk '{print $1 " " $3}' | sed -e 's/\(^[0-6]\)/20\1/' -e 's/\(^[7-9]\)/19\1/' -e 's/-99.0000/-999.9/' >> tsi_daily.dat
daily2longer tsi_daily.dat 12 mean > tsi.dat
$HOME/NINO/copyfilesall.sh tsi_daily.dat tsi.dat
