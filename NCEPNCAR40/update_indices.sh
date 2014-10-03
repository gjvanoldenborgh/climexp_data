#!/bin/sh
cp qbo.data qbo.data.old
wget -N http://www.cdc.noaa.gov/Correlation/qbo.data
mv nqbo.dat nqbo.dat.old
cat << EOF > nqbo.dat
# QBO index by Cathy Smith from the NCEP/NCAR reanalysis
# available from <a href="http://www.cdc.noaa.gov/ClimateIndices/List/#QBO">CDC</a>
# last updated: `date +"%Y-%m-%d"`
EOF
egrep -v '^ ' qbo.data | sed -e 's/999.0/999.9/g' >> nqbo.dat
$HOME/NINO/copyfiles.sh nqbo.dat
