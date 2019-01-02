#!/bin/sh
echo "# 20th century global mean sea level by <a href=\"http://www.nature.com/nature/journal/v517/n7535/full/nature14093.html?foxtrotcallback=true\">Hay et al</a>" > ssh_hay.dat
echo "# ssh [mm] global mean sea level" >> ssh_hay.dat
tail -n +3 Hay2015.csv | cut -d ';' -f 1-2 | tr ';,' ' .' >> ssh_hay.dat
echo "# 20th century global mean sea level by <a href=\"http://www.nature.com/nature/journal/v517/n7535/full/nature14093.html?foxtrotcallback=true\">Hay et al</a>" > dssh_hay.dat
echo "# dssh [mm] 95% CI uncertainty on global mean sea level" >> dssh_hay.dat
tail -n +3 Hay2015.csv | cut -d ';' -f 1,3 | tr ';,' ' .' >> dssh_hay.dat
$HOME/NINO/copyfilesall.sh ssh_hay.dat dssh_hay.dat