#!/bin/bash

# SAM

get_index slp.mon.mean.nc 0 360 -40 -40 nearest > slp40.dat
get_index slp.mon.mean.nc 0 360 -65 -65 nearest > slp65.dat
normdiff slp40.dat slp65.dat year none | sed -e 's/diff.*$/SAM [1] Southern Annular Mode/' > sam_ncepncar.dat
$HOME/NINO/copyfiles.sh sam_ncepncar.dat

# Cathy's QBO

cp qbo.data qbo.data.old
wget -N --no-check-certificate https://www.esrl.noaa.gov/psd/data/correlation/qbo.data
mv nqbo.dat nqbo.dat.old
cat << EOF > nqbo.dat
# QBO index by PSD from  the zonal average of the 30mb zonal wind at the equator in the NCEP/NCAR reanalysis
# available from <a href="https://www.esrl.noaa.gov/psd/data/climateindices/list/#QBO">ESRL</a>
# QBO [1] QBO index
EOF
egrep -v '^ ' qbo.data | sed -e 's/999.0/999.9/g' >> nqbo.dat
$HOME/NINO/copyfiles.sh nqbo.dat
