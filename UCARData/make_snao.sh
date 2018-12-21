#!/bin/bash
if [ ! -s snao_ucar.ctl ]; then
	eof ds010_1.ctl 1 mon 7 ave 2 begin 1950 end 2010 lon1 -90 lon2 30 lat1 40 lat2 70 snao_ucar.ctl
fi
patternfield ds010_1.ctl snao_ucar.ctl eof1 7 > snao_raw.dat
cat <<EOF > snao_ucar.dat
# Summer NAO index (PC of first EOF of SLP over 40-70N, 90W-30E July-August average over 1950-2010)
# based on the UCAR (Trenbert and Paolino) sea-level pressure reconstruction
# SNAO [1] UCAR Summer NAO
EOF
normdiff snao_raw.dat nothing mon mon | fgrep -v '#' >> snao_ucar.dat
$HOME/NINO/copyfilesall.sh snao_ucar.dat
