#!/bin/sh
echo "# 1880-2013 global mean sea level by <a href=\"https://link.springer.com/article/10.1007/s10712-011-9119-1\">Church and White</a>" > ssh_church.dat
echo "# ssh [mm] global mean sea level" >> ssh_church.dat
cat CSIRO_Recons_gmsl_yr_2015.txt | cut -b 1-14 >> ssh_church.dat
echo "# 20th century global mean sea level by <a href=\"https://link.springer.com/article/10.1007/s10712-011-9119-1\">Church and White</a>" > dssh_church.dat
echo "# dssh [mm] 95% CI uncertainty on global mean sea level" >> dssh_church.dat
cat CSIRO_Recons_gmsl_yr_2015.txt | cut -b 1-7,15- >> dssh_church.dat
$HOME/NINO/copyfilesall.sh ssh_church.dat dssh_church.dat