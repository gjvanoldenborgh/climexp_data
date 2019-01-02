#!/bin/sh

wget -N --no-check-certificate http://www.eiscat.rl.ac.uk/Members/mike/Open%20solar%20flux%20data/openflux1675to2010.txt

cat > osf.dat << EOF
# <a href="http://www.eiscat.rl.ac.uk/Members/mike/Open%20solar%20flux%20data/openflux1675to2010.txt">Open solar flux</a> from model and geomagnetic activity data
# values after 1900 are from geomagnetic activity using the aa and m indices using the method of Lockwood et al. (2009)
# values before 1900 are from the model of Vieira and Solanki (2010)
# osf [10^14 Wb] Open Solar Flux
EOF
egrep -v '^%' openflux1675to2010.txt | awk '{print $1 " " $2}' >> osf.dat

cat > osf_obs.dat << EOF
# <a href="http://www.eiscat.rl.ac.uk/Members/mike/Open%20solar%20flux%20data/openflux1675to2010.txt">Open solar flux</a> from near-Earth IMF magnetometer data
# osf [10^14 Wb] Open Solar Flux
EOF
egrep -v '^%' openflux1675to2010.txt | fgrep -v NaN | awk '{print $1 " " $3}' >> osf_obs.dat

../copyfilesall.sh osf*.dat
