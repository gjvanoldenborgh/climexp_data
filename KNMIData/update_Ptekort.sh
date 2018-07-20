#!/bin/sh
file=hist_Ptekort.dat
cat <<EOF > $file
# max potentieel neerslagtekort april t/m september
# Epot-P [mm] maximum potentieel neerslagtekort in De Bilt
# Potential evaporation estimate with the <a href="https://nl.wikipedia.org/wiki/Referentie-gewasverdamping">Makkink method</a> that uses only temperature and global radiation
# Global radiation is derived from sunshine dutaion 1906-2000, observed at De Bilt afterwards
# Precipitation is the <a href="https://climexp.knmi.nl/getindices.cgi?KNMIData/precip13stations">P13 series</a>, validated but non-homogenised 1906-2016. 2017 is unvalidated.
# Values deviate slightly from the graphs at the <a href="https://www.knmi.nl/nederland-nu/klimatologie/geografische-overzichten/neerslagtekort_droogte">KNMI site</a> that are based on real-time unvalidated precipitation data.
# contact :: beersma@knmi.nl
# institution :: KNMI
# history :: converted `date`
EOF
fgrep -v '#' hist_Ptekort2.dat | cut -b1-5,11-16 >> $file
