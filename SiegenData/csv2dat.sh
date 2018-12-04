#!/bin/sh
echo "# 20th century global mean sea level by <a href=\"http://www.pnas.org/content/114/23/5946.abstract\">Dangendorf et al</a>" > ssh_dangendorf.dat
echo "# ssh [mm] global mean sea level" >> ssh_dangendorf.dat
tail -n +2 GMSL_Dangendorf.csv | cut -d ';' -f 1-2 | tr ';,' ' .' >> ssh_dangendorf.dat
echo "# 20th century global mean sea level by <a href=\"http://www.pnas.org/content/114/23/5946.abstract\">Dangendorf et al</a>" > dssh_dangendorf.dat
echo "# dssh [mm] 95% CI uncertainty on global mean sea level" >> dssh_dangendorf.dat
tail -n +2 GMSL_Dangendorf.csv | cut -d ';' -f 1,3 | tr ';,' ' .' >> dssh_dangendorf.dat
$HOME/NINO/copyfilesall.sh ssh_dangendorf.dat dssh_dangendorf.dat