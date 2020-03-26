#!/bin/sh
if [ ! -s eof_nao_ncepncar.nc ]; then
    eof slp.mon.mean.nc 1 mon 12 sel 4 anomal lon1 -90 lon2 30 lat1 0 lat2 90 end 2018 eof_nao_ncepncar.nc
    fi
patternfield slp.mon.mean.nc eof_nao_ncepncar.nc eof1 12 > nao_raw.dat
cat <<EOF > snao_ncepncar.dat
# NAO index (PC of first EOF of SLP over 0-90N, 90W-30E December-March months)
# based on the NCEP/NCAR R1 reanalysis sea-level pressure reconstruction
# NAO [1] NCEP/NCAR North Atlantic Oscillation Index
EOF
normdiff nao_raw.dat nothing mon mon | fgrep -v '[' | egrep -v 'and nothing|normalized' >> nao_ncepncar.dat
$HOME/NINO/copyfilesall.sh nao_ncepncar.dat
