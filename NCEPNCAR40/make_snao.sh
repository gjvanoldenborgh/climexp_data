#!/bin/sh
if [ ! -s snao_ncepncar.nc ]; then
	eof slp.mon.mean.nc 1 mon 7 ave 2 begin 1950 end 2010 lon1 -90 lon2 30 lat1 40 lat2 70 snao_ncepncar.nc
fi
patternfield slp.mon.mean.nc snao_ncepncar.nc eof1 7 > snao_raw.dat
cat <<EOF > snao_ncepncar.dat
# Summer NAO index (PC of first EOF of SLP over 40-70N, 90W-30E July-August average over 1950-2010)
# based on the NCEP/NCAR R1 reanalysis sea-level pressure reconstruction
# SNAO [1] NCEP/NCAR Summer NAO
EOF
normdiff snao_raw.dat nothing mon mon | fgrep -v '#' >> snao_ncepncar.dat
$HOME/NINO/copyfilesall.sh snao_ncepncar.dat
