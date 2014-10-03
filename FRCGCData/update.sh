#!/bin/sh
wget -N http://www.jamstec.go.jp/frcgc/research/d1/iod/DATA/dmi_HadISST.txt
cat > dmi_hadisst.dat << EOF
# Indian Ocean Dipole Mode Index from <a href="http://www.jamstec.go.jp/frsgc/research/d1/iod/">FRCGC</a>
# based on HadISST
# DMI [1]
EOF
cat dmi_HadISST.txt >> dmi_hadisst.dat
$HOME/NINO/copyfiles.sh dmi_hadisst.dat
