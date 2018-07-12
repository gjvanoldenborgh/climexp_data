#!/bin/sh
wget -N ftp://ftp.pmodwrc.ch/pub/data/irradiance/composite/DataPlots/ext_composite_42_65_*.dat
file=`ls -t ext_composite_*.dat | head -1`
version=${file%.dat}
version=${version#ext_composite_}
cat > tsi_daily.dat <<EOF
# Observed solar constant reconstructed from satellite observations.
# <a href="https://www.pmodwrc.ch/forschung-entwicklung/solarphysik/tsi-composite/">source</a>
# TSI [W/m2] PMOD total solar irradiance
# institute :: PMOD/WRC
# contact :: claus.froehlich@pmodwrc.ch
# version :: $version
# references :: C. Fröhlich, 2000, "Observations of Irradiance Variations, Space Science Rev., 94, pp. 15-24. ftp://ftp.pmodwrc.ch/pub/Claus/ISSI_WS2005/ISSI2005a_CF.pdf
# source :: https://www.pmodwrc.ch/en/research-development/solar-physics/tsi-composite/
# source_url :: ftp://ftp.pmodwrc.ch/pub/data/irradiance/composite/
# retrieved :: `date`
# climexp_url :: https://climexp.knmi.nl/getindices.cgi?PMODData/tsi_daily
EOF
comment=`head -n 100 $file | sed -e '1,/Comment/d' -e '/Description/,$d' | tr ';' '  ' | tr -d '\r\n'`
echo "# comment :: $comment" >> tsi_daily.dat
tail -n +2 $file | egrep -v '^;' | awk '{print $1 " " $3}' | sed -e 's/\(^[0-6]\)/20\1/' -e 's/\(^[7-9]\)/19\1/' -e 's/-99.0000/-999.9/' -e 's/-98.6318/-999.9/' -e 's/-98.6251/-999.9/' >> tsi_daily.dat
daily2longer tsi_daily.dat 12 mean | sed -e 's@/tsi_daily@/tsi@' > tsi.dat
$HOME/NINO/copyfilesall.sh tsi_daily.dat tsi.dat
