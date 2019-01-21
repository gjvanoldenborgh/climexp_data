#!/bin/sh
file=OSF_KC_annual_to18.txt
# got the latest version  by email 20-jan-2019
###wget -N --no-check-certificate http://www.eiscat.rl.ac.uk/Members/mike/Open%20solar%20flux%20data/openflux1675to2010.txt

cat > osf.dat << EOF
# Open solar flux by M.Lockwood, University of Reading kinematically corrected to remove folded flux
# contact :: m.lockwood@reading.ac.uk
# institution :: University of Reading
# references :: M. Lockwood, M. Owens, and A.P. Rouillard (2009) Excess Open Solar Magnetic Flux from Satellite Data: II. A survey of kinematic effects. J. Geophys. Res., 114, A11104, doi:10.1029/2009JA014450 ; M. Lockwood, M. Owens, and A.P. Rouillard (2009). Excess Open Solar Magnetic Flux from Satellite Data: I. Analysis of the 3rd Perihelion Ulysses Pass. J. Geophys. Res., 114, A11103, doi:10.1029/2009JA014449
# history :: converted `date`
# osf [10^15 Wb] Open Solar Flux
EOF
egrep -v '^%' $file | sed -e 's/NaN/-999.9/' >> osf.dat

cat > osf_hist.dat << EOF
# <a href="http://www.eiscat.rl.ac.uk/Members/mike/Open%20solar%20flux%20data/openflux1675to2010.txt">Open solar flux</a> from model and geomagnetic activity data
# values after 1900 are from geomagnetic activity using the aa and m indices using the method of Lockwood et al. (2009)
# values before 1900 are from the model of Vieira and Solanki (2010)
# osf [10^14 Wb] Open Solar Flux
EOF
egrep -v '^%' openflux1675to2010.txt | awk '{print $1 " " $2}' >> osf_hist.dat
scaleseries 0.1 osf_hist.dat > osf_hist1.dat
patchseries osf.dat osf_hist1.dat none > osf_merged.dat

cat > osf_obs.dat << EOF
# <a href="http://www.eiscat.rl.ac.uk/Members/mike/Open%20solar%20flux%20data/openflux1675to2010.txt">Open solar flux</a> from near-Earth IMF magnetometer data
# osf [10^14 Wb] Open Solar Flux
EOF
egrep -v '^%' openflux1675to2010.txt | fgrep -v NaN | awk '{print $1 " " $3}' >> osf_obs.dat
v

make 27today
./27today OSF_KC_27day_to18.txt > osf_daily.dat
fgrep '#' osf.dat > osf_mo.dat
echo '# interpolated from 27-day to month by GJvO' >> osf_mo.dat
daily2longer osf_daily.dat 12 mean | 2>&1 fgrep -v disregarded | fgrep -v '#' >> osf_mo.dat

../copyfilesall.sh osf*.dat
