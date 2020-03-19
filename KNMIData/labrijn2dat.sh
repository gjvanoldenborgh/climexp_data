#!/bin/sh
# replacement for old Fortran code
# copied from the header of LABRIJN.txt
cat > labrijn_01.dat <<EOF
# Tair [Celsius] Surface air temperature at De Bilt
# based on Delft/Rijnsburg (1706-1734), Zwanenburg (1735-1800 & 1811-1848), Haarlem (1801-1810) and Utrecht (1849-1897) reduced to De Bilt'
# and De Bilt (1898-now, homogenised 1906-now).
# references ::  A. Labrijn, Nicolaus Cruquius (1678-1754) and his meteorological observations. M&V 49, KNMI, 1945, A. van Engelen and H. Geurts, Het klimaat van het hoofdobservatorium De Bilt in de jaren 1901-1984. Klimatologische Dienst, publ. 150-25, KNMI, 1985.
# longitude :: 5.18 degrees_east
# latitude :: 52.10 degrees_north
# institution :: KNMI
# source_url :: http://projects.knmi.nl/klimatologie/daggegevens/antieke_wrn/index.html
# climexp_url :: https://climexp.knmi.nl/getindices.cgi?WMO=KNMIData/labrijn&STATION=Tdebilt&TYPE=i
EOF
fgrep -v ',,,,,,,,,,,,,,,,,' LABRIJN.txt | tail -n +2 | tr -d '" ' \
    | sed -e 's/,,/,-999.9,/g' -e 's/,,/,-999.9,/g' \
        -e 's/\([^,]*\),\([^,]*\),\([^,]*\),\([^,]*\),\([^,]*\),\([^,]*\),\([^,]*\),\([^,]*\),\([^,]*\),/\1 \2 \3 \4 \5 \6 \7 \8 \9 /' \
        -e 's/\([^,]*\),\([^,]*\),\([^,]*\),\([^,]*\).*/\1 \2 \3 \4/' \
        >> labrijn_01.dat
scaleseries 0.1 labrijn_01.dat > labrijn_org.dat
# use homogenised data from 1906 onward
egrep -v '^ (190[6-9]|19[1-9][0-9]|20[0-9][0-9])' labrijn_org.dat > labrijn_old.dat
patchseries labrijn_old.dat temp_De_Bilt_hom.dat > labrijn.dat

        