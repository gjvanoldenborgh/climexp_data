#!/bin/sh
if [ ! -s eof_nao_erai.nc ]; then
    eof erai_msl_extended.nc 1 mon 12 sel 4 anomal lon1 -90 lon2 30 lat1 0 lat2 90 end 2018 xave 2 yave 2 eof_nao_erai.nc
    fi
patternfield erai_msl_extended.nc eof_nao_erai.nc eof1 12 > nao_raw1.dat
scaleseries -1 nao_raw1.dat > nao_raw.dat
cat <<EOF > nao_erai.dat
# NAO index (PC of first EOF of SLP over 0-90N, 90W-30E December-March months)
# based on the ERA-interim reanalysis / ECMWF analysis sea-level pressure reconstruction
# NAO [1] ERA-interim /ECMWF analyses North Atlantic Oscillation Index
EOF
normdiff nao_raw.dat nothing mon mon | fgrep -v '[' | egrep -v 'and nothing|normalized' >> nao_erai.dat
$HOME/NINO/copyfilesall.sh nao_erai.dat

# daily: not yet ready
exit

patternfield erai_msl_daily_extended.nc eof_nao_erai.nc eof1 12 > nao_raw1.dat
scaleseries -1 nao_raw1.dat > nao_raw.dat
cat <<EOF > nao_erai_daily.dat
# NAO index (PC of first EOF of monthly SLP over 0-90N, 90W-30E December-March months)
# based on the ERA-interim reanalysis / ECMWF analysis sea-level pressure reconstruction
# NAO [1] ERA-interim /ECMWF analyses North Atlantic Oscillation Index
EOF
normdiff nao_raw.dat nothing mon mon | fgrep -v '[' | egrep -v 'and nothing|normalized' >> nao_erai_daily.dat
$HOME/NINO/copyfilesall.sh nao_erai_daily.dat