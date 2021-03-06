#!/bin/sh
force="$1"

for file in ersst4.nino.mth.81-10.ascii sstoi.indices
do
    cp $file $file.old
    wget -q -N --no-check-certificate https://www.cpc.ncep.noaa.gov/data/indices/$file
    diff $file $file.old
    if [ $? != 0 -o "$force" = force ]; then
        echo "new $file differs from old one"
        rm $file.old
        sstoi2dat $file
    else
        echo "new $file is the same as old one, keeping old one"
    fi
done
# extend with Kaplan inices, offset added to reflect differing climateologies.
sstoi2dat sstoi.indices # otherwise it accumulates...
for i in 2 3 4 5
do
    patchseries nino$i.dat kaplan_nino$i.dat noscale > aap.dat
    mv aap.dat nino$i.dat
done
$HOME/NINO/copyfilesall.sh *nino?.dat sstoi.indices

# NCEP detrended
wget -q -N --no-check-certificate https://www.cpc.ncep.noaa.gov/products/analysis_monitoring/ensostuff/detrend.nino34.ascii.txt
echo "# dNINO34 [K] NCEP detrended Nino3.4 index" > nino34_detrended_ncep.dat
echo "# <a href=https://www.cpc.ncep.noaa.gov/products/analysis_monitoring/ensostuff/ONI_change.shtml>using running 30-yr base periods</a>" >> nino34_detrended_ncep.dat
fgrep -v YR detrend.nino34.ascii.txt | cut -b 1-8,25-  >> nino34_detrended_ncep.dat

make normalize_wksst ninoweek2daily
cp wksst8110.for wksst8110.for.old
wget -q -N --no-check-certificate https://www.cpc.ncep.noaa.gov/data/indices/wksst8110.for
diff wksst8110.for wksst8110.for.old
if [ $? != 0 -o "$force" = force ]; then
  echo "new  wksst8110.for differs from old one"
  rm wksst8110.for.old
  ./normalize_wksst wksst8110.for > wksst.myfor
  echo 'y' | gnuplot plotninoweek.gnu
  gs -q -r300 -dTextAlphaBits=4 -dGraphicsAlphaBits=4 -dNOPAUSE -sDEVICE=ppmraw -sOutputFile=plotninoweek.ppm plotninoweek.eps -c quit
###  gsppm plotninoweek.ppm plotninoweek.eps
  pnmcrop plotninoweek.ppm | pnmscale 0.319 | pnmcut -left=1 | pnmtopng > ! plotninoweek.png
  rm -f plotninoweek.ppm
  epstopdf plotninoweek.eps
  ###cp -f plotninoweek.png /usr/people/oldenbor/www2/research/global_climate/enso
  ./ninoweek2daily
  for index in nino2 nino3 nino4 nino5
  do
    daily2longer ${index}_weekly.dat 73 mean > ${index}_5daily.dat
  done
else
  echo "new wksst8110.for is the same as old one, keeping old one"
fi
$HOME/NINO/copyfilesall.sh plotninoweek.??? 
$HOME/NINO/copyfiles.sh nino?_weekly.dat nino??_weekly.dat
$HOME/NINO/copyfiles.sh nino?_5daily.dat nino??_5daily.dat

make makesoi
cp soi soi.old
wget -q -N --no-check-certificate https://www.cpc.ncep.noaa.gov/data/indices/soi
diff soi soi.old
if [ $? != 0 -o "$force" = force ]; then
  echo "new file differs from old one"
  rm soi.old
  ./makesoi > cpc_soi.dat
else
  echo "new soi is the same as old one, keeping old one"
fi
$HOME/NINO/copyfilesall.sh cpc_soi.dat

make tele2dat
cp tele_index.nh tele_index.nh.old
wget -q -N ftp://ftp.cpc.ncep.noaa.gov/wd52dg/data/indices/tele_index.nh
diff tele_index.nh tele_index.nh.old
if [ $? != 0 -o "$force" = force ]; then
  echo "new file differs from old one"
  rm tele_index.nh.old
  ./tele2dat
else
  echo "new tele_index.nh is the same as old one, keeping old one"
fi
$HOME/NINO/copyfilesall.sh cpc_nao.dat cpc_ea.dat cpc_wp.dat cpc_epnp.dat cpc_pna.dat cpc_ea_wr.dat cpc_sca.dat cpc_tnh.dat cpc_pol.dat cpc_pt.dat

make mjo2dat
cp proj_norm_order.ascii proj_norm_order.ascii.old
wget -q -N --no-check-certificate https://www.cpc.ncep.noaa.gov/products/precip/CWlink/daily_mjo_index/proj_norm_order.ascii
diff proj_norm_order.ascii proj_norm_order.ascii.old
if [ $? != 0 -o "$force" = force ]; then
  echo "new file differs from old one"
  rm proj_norm_order.ascii.old
    ./mjo2dat
  for file in cpc_mjo*_daily.dat
  do
    daily2longer $file 12 mean > `basename $file _daily.dat`_mean12.dat
  done
else
  echo "new proj_norm_order.ascii is the same as old one, keeping old one"
fi
$HOME/NINO/copyfiles.sh cpc_mjo*.dat

cp heat_content_index.txt heat_content_index.txt.old
wget -q -N --no-check-certificate https://www.cpc.ncep.noaa.gov/products/analysis_monitoring/ocean/index/heat_content_index.txt
diff heat_content_index.txt heat_content_index.txt.old
if [ $? != 0 -o "$force" = force ]; then
  url=https://www.cpc.noaa.gov/products/analysis_monitoring/ocean/index/heat_content_index.txt
  cat > cpc_eq_heat300.dat <<EOF
# <a href="$url">CPC/NCEP</a> Equatorial Upper 300m temperature Average anomaly based on 1981-2010 Climatology, 130E-80W
# institution :: NOAA/NCEP/CPC
# source :: $url
# history :: retrieved on `date`
# heat300 [K] temperature averaged to 300m
EOF
  tail -n +3 heat_content_index.txt | cut -b 1-20 >> cpc_eq_heat300.dat
else
  echo "new heat_content_index.txt is the same as old one, keeping old one"
fi
$HOME/NINO/copyfiles.sh cpc_eq_heat300.dat

./update_annular.sh
./update_daily.sh
./merge_telecon.sh cmorph