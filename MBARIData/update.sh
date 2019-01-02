#!/bin/sh
# update the Mset :-) from the Monterey Bay Aquarium Research Institute
url=http://www.mbari.org/bog/GlobalModes/Indices.htm
data=http://www.mbari.org/bog/GlobalModes/Mset.htm

wget -N -q $data
sed -e 's/<[^>]*>//g' -e '1,/M6/d' -e 's/\t//' Mset.htm > Mset.txt
./txt2dat Mset.txt
$HOME/NINO/copyfiles.sh M?.dat
