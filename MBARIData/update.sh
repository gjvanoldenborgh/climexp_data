#!/bin/sh
# update the Mset :-) from the Monterey Bay Aquarium Research Institute
url=https://www.mbari.org/science/upper-ocean-systems/biological-oceanography/global-modes-of-sea-surface-temperature/
data=https://www3.mbari.org/science/upper-ocean-systems/biological-oceanography/GlobalModes/Mset.htm

wget -N -q --no-check-certificate $data
sed -e 's/<[^>]*>/ /g' -e '1,/M6/d' -e 's/\t//' Mset.htm > Mset.txt
make txt2dat
./txt2dat Mset.txt
$HOME/NINO/copyfiles.sh M?.dat
