#!/bin/sh
wget --no-check-certificate -N https://www.pmel.noaa.gov/tao/wwv/data/wwv.dat

cat <<EOF > tao_wwv.dat
# TAO <a href="https://www.pmel.noaa.gov/elnino/upper-ocean-heat-content-and-enso">Warm Water Volume</a>
# reference :: Meinen, C. S. and M. J. McPhaden, 2000, Observations of Warm Water Volume Changes in the Equatorial Pacific and Their Relationship to El Niño and La Niñ̃a, J.Clim, 13, 3551-3559
# institution :: TAO Project Office/NOAA/PMEL/Seattle
# contact :: Michael J. McPhaden, Director
# source :: http://www.pmel.noaa.gov/tao/elnino/wwv/data/wwv.dat
# history :: retrieved on `date`
# WWV [m^3] Warm Water Volume 5N-5S, 120E-80W
EOF
egrep '^[12]' wwv.dat | awk '{print $1 " " $2}' >> tao_wwv.dat

cat <<EOF > tao_wwva.dat
# TAO <a href="https://www.pmel.noaa.gov/elnino/upper-ocean-heat-content-and-enso">Warm Water Volume</a>
# reference :: Meinen, C. S. and M. J. McPhaden, 2000, Observations of Warm Water Volume Changes in the Equatorial Pacific and Their Relationship to El Niño and La Niñ̃a, J.Clim, 13, 3551-3559
# institution :: TAO Project Office/NOAA/PMEL/Seattle
# contact :: Michael J. McPhaden, Director
# source :: http://www.pmel.noaa.gov/tao/elnino/wwv/data/wwv.dat
# history :: retrieved on `date`
# WWVa [m^3] Warm Water Volume anomalies 5N-5S, 120E-80W
EOF
egrep '^[12]' wwv.dat | awk '{print $1 " " $3}' >> tao_wwva.dat

$HOME/NINO/copyfiles.sh tao_wwv.dat tao_wwva.dat