#!/bin/sh

cp newsam.1957.2007.txt newsam.1957.2007.txt.old
wget -N http://www.nerc-bas.ac.uk/public/icd/gjma/newsam.1957.2007.txt
cat > bas_sam.dat <<EOF
# Southern Annular Mode from <a href="http://www.nerc-bas.ac.uk/icd/gjma/sam.html">BAS</a>
# SAM [1] Southern Annular Mode
EOF
year=`date "+%Y"`
tail -n +3 newsam.1957.2007.txt | sed "s/^$year\(.*\)/$year\1 -999.9 -999.9 -999.9 -999.9 -999.9 -999.9 -999.9 -999.9 -999.9 -999.9 -999.9/" >> bas_sam.dat

$HOME/NINO/copyfiles.sh bas_sam.dat
