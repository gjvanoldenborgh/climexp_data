#!/bin/sh
# replacement for old Fortran code
# copied from the header of LABRIJN.txt
cat > labrijn_01.dat <<EOF
# Tair [Celsius] Surface air temperature at De Bilt
# based on Delft/Rijnsburg (1706-1734), Zwanenburg (1735-1800 & 1811-1848), Haarlem (1801-1810) and Utrecht (1849-1897) reduced to De Bilt'
# and  De Bilt (unhomogenised, 1898-present)
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
patchseries labrijn_org.dat tg260_mean12.dat > labrijn.dat

        