#!/bin/sh
get_index ersstv4.nc 0 360 -20 20 > ersst_tropical.dat

for nino in 12 3 3.4 4
do
  get_index ersstv4.nc mask ersstv4_nino${nino}_mask.nc > ersst_nino${nino}.dat
  egrep '^#' ersst_nino${nino}.dat | sed -e 's/SST/SSTA/' > ersst_nino${nino}a.dat
  echo '# SSTA normalized to 1981-2010' >> ersst_nino${nino}a.dat
  plotdat anomal 1981 2010 ersst_nino${nino}.dat | fgrep -v repeat >> ersst_nino${nino}a.dat

  if [ ! -s corr_nino${nino}_20S20N.txt ]; then
    correlate ersst_tropical.dat file ersst_nino${nino}a.dat mon 1:12 ave 3 diff plot corr_nino${nino}_20S20N.txt
  fi
  factor=`./convert_regression corr_nino${nino}_20S20N.txt`

  normdiff ersst_nino${nino}.dat ersst_tropical.dat none none > aap.dat
  scaleseries $factor aap.dat > ersst_nino${nino}_rel.dat
  egrep '^#' ersst_nino${nino}.dat | sed -e 's/SST/SSTA/' > ersst_nino${nino}a_rel.dat
  echo '# SSTA normalized to 1981-2010' >> ersst_nino${nino}a_rel.dat
  plotdat anomal 1981 2010 ersst_nino${nino}_rel.dat | fgrep -v repeat | fgrep -v normal  >> ersst_nino${nino}a_rel.dat
done
