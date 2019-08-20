#!/bin/sh
echo "# 20th century global mean sea level by <a href=\"https://www.nature.com/articles/s41558-019-0531-8\">Dangendorf et al, 2019</a>" > ssh_dangendorf_mo.dat
echo "# ssh [mm] global mean sea level" >> ssh_dangendorf_mo.dat
tail -n +2 DataDangendorf2019.txt | cut -b 1-35 | sed -e 's/1900    /1900.000/' >> ssh_dangendorf_mo.dat

echo "# 20th century global mean sea level by <a href=\"https://www.nature.com/articles/s41558-019-0531-8\">Dangendorf et al 2019</a>" > dssh_dangendorf_mo.dat
echo "# dssh [mm] 95% CI uncertainty on global mean sea level" >> dssh_dangendorf_mo.dat
tail -n +2 DataDangendorf2019.txt | cut -b 1-18,36-54 | tr ';,' ' .' >> dssh_dangendorf_mo.dat
$HOME/NINO/copyfilesall.sh ssh_dangendorf_mo.dat dssh_dangendorf_mo.dat

echo "# 20th century global mean sea level by <a href=\"http://www.pnas.org/content/114/23/5946.abstract\">Dangendorf et al</a>" > ssh_dangendorf.dat
echo "# ssh [mm] global mean sea level" >> ssh_dangendorf.dat
tail -n +2 GMSL_Dangendorf.csv | cut -d ';' -f 1-2 | tr ';,' ' .' >> ssh_dangendorf.dat
echo "# 20th century global mean sea level by <a href=\"http://www.pnas.org/content/114/23/5946.abstract\">Dangendorf et al</a>" > dssh_dangendorf.dat
echo "# dssh [mm] 95% CI uncertainty on global mean sea level" >> dssh_dangendorf.dat
tail -n +2 GMSL_Dangendorf.csv | cut -d ';' -f 1,3 | tr ';,' ' .' >> dssh_dangendorf.dat
$HOME/NINO/copyfilesall.sh ssh_dangendorf.dat dssh_dangendorf.dat