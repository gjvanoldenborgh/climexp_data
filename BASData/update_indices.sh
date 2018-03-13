#!/bin/sh

cp newsam.1957.2007.txt newsam.1957.2007.txt.old
wget -N http://www.nerc-bas.ac.uk/public/icd/gjma/newsam.1957.2007.txt
cat > bas_sam.dat <<EOF
# Southern Annular Mode from <a href="http://www.nerc-bas.ac.uk/icd/gjma/sam.html">BAS</a>
# SAM [1] BAS Southern Annular Mode index
# institution :: British Antarctic Survey
# source :: http://www.nerc-bas.ac.uk/icd/gjma/sam.html
# source_url :: http://www.nerc-bas.ac.uk/public/icd/gjma/newsam.1957.2007.txt
# references :: Marshall, G. J., 2003: Trends in the Southern Annular Mode from observations and reanalyses. J. Clim., 16, 4134-4143, https://doi.org/10.1175/1520-0442(2003)016<4134:TITSAM>2.0.CO;2
# history :: retrieved `date`
# climexp_url :: https://climexp.knmi.nl/getindices.cgi?BASData/sam
EOF
year=`date "+%Y"`
tail -n +3 newsam.1957.2007.txt | sed "s/^$year\(.*\)/$year\1 -999.9 -999.9 -999.9 -999.9 -999.9 -999.9 -999.9 -999.9 -999.9 -999.9 -999.9/" >> bas_sam.dat

$HOME/NINO/copyfiles.sh bas_sam.dat
