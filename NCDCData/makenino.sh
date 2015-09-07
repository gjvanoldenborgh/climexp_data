#!/bin/sh
for nino in 12 3 3.4 4
do
  get_index ersstv4.nc mask ersstv4_nino${nino}_mask.nc > ersst_nino${nino}.dat
  egrep '^#' ersst_nino${nino}.dat | sed -e 's/SST/SSTA/' > ersst_nino${nino}a.dat
  echo '# SSTA normalized to 1981-2010' >> ersst_nino${nino}a.dat
  plotdat anomal 1981 2010 ersst_nino${nino}.dat | fgrep -v repeat >> ersst_nino${nino}a.dat
done
