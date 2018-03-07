#!/bin/sh
if [ -z "$version" ]; then
    echo "$0: error: version unset"
    exit
fi
get_index ersst${version}.nc 0 360 -20 20 > ersst_tropical.dat

for nino in 12 3 3.4 4
do
  get_index ersst${version}.nc mask ersst${version}_nino${nino}_mask.nc | sed -e "s/spatial statistic of/Nino$nino index based on/" > ersst_nino${nino}.dat
  egrep '^#' ersst_nino${nino}.dat | fgrep -v '# sst [' | fgrep -v climexp_url > ersst_nino${nino}a.dat
  echo "# climexp_url :: https://climexp.knmi.nl/getindices.cgi?NCDCData/ersst_nino${nino}a" >> ersst_nino${nino}a.dat
  echo '# SSTA normalized to 1981-2010' >> ersst_nino${nino}a.dat
  echo "# Nino$nino [K] ERSST $version Nino$nino index" >> ersst_nino${nino}a.dat
  plotdat anomal 1981 2010 ersst_nino${nino}.dat | fgrep -v repeat | egrep -v '^#' >> ersst_nino${nino}a.dat

  if [ ! -s corr_nino${nino}_20S20N.txt ]; then
    correlate ersst_tropical.dat file ersst_nino${nino}a.dat mon 1:12 ave 3 diff plot corr_nino${nino}_20S20N.txt
  fi
  factor=`./convert_regression corr_nino${nino}_20S20N.txt`

  normdiff ersst_nino${nino}.dat ersst_tropical.dat none none > aap.dat
  scaleseries $factor aap.dat > ersst_nino${nino}_rel.dat
  egrep '^#' ersst_nino${nino}a.dat | fgrep -v '[K]' > ersst_nino${nino}a_rel.dat
  echo "# Nino$nino index minus 20S-20N average SST" >> ersst_nino${nino}a_rel.dat
  echo "# normalised by a factor $factor" >> ersst_nino${nino}a_rel.dat
  echo "# Nino${nino}r [K]  ERSST $version relative Nino$nino index" >> ersst_nino${nino}a_rel.dat
  plotdat anomal 1981 2010 ersst_nino${nino}_rel.dat | fgrep -v repeat | egrep -v '^#'  >> ersst_nino${nino}a_rel.dat
done
