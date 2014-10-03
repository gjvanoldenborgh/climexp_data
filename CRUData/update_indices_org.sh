#!/bin/csh -f
#
# NAO
#
cp nao_update.htm nao_update.htm.old
wget -N http://www.cru.uea.ac.uk/~timo/projpages/nao_update.htm
make update_nao
./update_nao > nao.dat
scp nao.dat bhlclim:CRUData/
#
# SOI
#
cp soi.dat soi.dat.old
wget -N -O soi.dat.downloaded http://www.cru.uea.ac.uk/ftpdata/soi.dat
cat <<EOF > soi.dat
# SOI (Southern Oscillation Index) from CRU
# <a href="http://www.cru.uea.ac.uk/cru/data/soi.htm">data description</a>
# 
#
#
EOF
sed -e 's/-10\.00/-999.9/g' soi.dat.downloaded >> soi.dat
diff soi.dat soi.dat.old
if ( $status ) then
  rm -i soi.dat.old
  $HOME/NINO/Fortran/filtermonthseries lo box 5 soi.dat >! soi5.dat
  scp soi.dat soi5.dat bhlclim:CRUData/
else
  echo "soi.dat has not changed"
  mv soi.dat.old soi.dat
endif
#
# old global and hemispheric temperatures
#
cp tavenh2v.dat tavenh2v.dat.old
wget -N http://www.cru.uea.ac.uk/ftpdata/tavenh2v.dat
diff tavenh2v.dat tavenh2v.dat.old
if ( $status ) then
  mv tavesh2v.dat tavesh2v.dat.old
  wget http://www.cru.uea.ac.uk/ftpdata/tavesh2v.dat
  mv tavegl2v.dat tavegl2v.dat.old
  wget http://www.cru.uea.ac.uk/ftpdata/tavegl2v.dat
  mv taveglobal2v.dat taveglobal2v.dat.old
  mv tavenorth2v.dat tavenorth2v.dat.old
  mv tavesouth2v.dat tavesouth2v.dat.old
  ./dat2dat < tavegl2v.dat > taveglobal2v.dat
  ./dat2dat < tavenh2v.dat > tavenorth2v.dat
  ./dat2dat < tavesh2v.dat > tavesouth2v.dat
  scp tavesouth2v.dat tavenorth2v.dat taveglobal2v.dat bhlclim:CRUData/
  head -5 taveglobal2v.dat > taveglobal2v_yr.dat
  tail -n +6 taveglobal2v.dat | awk '{print $1 "  " $14}' >> taveglobal2v_yr.dat
  head -5 tavenorth2v.dat > tavenorth2v_yr.dat
  head -5 tavenorth2v.dat > tavenorth2v_yr.dat
  tail -n +6 tavenorth2v.dat | awk '{print $1 "  " $14}' >> tavenorth2v_yr.dat
  head -5 tavesouth2v.dat > tavesouth2v_yr.dat
  head -5 tavesouth2v.dat > tavesouth2v_yr.dat
  tail -n +6 tavesouth2v.dat | awk '{print $1 "  " $14}' >> tavesouth2v_yr.dat
  scp taveglobal2v_yr.dat tavenorth2v_yr.dat tavesouth2v_yr.dat bhlclim:CRUData/
else
  echo "no change in tavenh2v.dat"
  mv tavenh2v.dat.old tavenh2v.dat
endif
#
# global and hemispheric temperatures
#
foreach version ( 3 3v )
  foreach area ( gl sh nh )
    cp hadcrut${version}${area}.txt hadcrut${version}${area}.txt.old
    wget -N http://www.cru.uea.ac.uk/cru/data/temperature/hadcrut${version}${area}.txt
    diff  hadcrut${version}${area}.txt hadcrut${version}${area}.txt.old
    if ( $status ) then
      mv hadcrut${version}${area}.dat hadcrut${version}${area}.dat.old
      ./dat2dat $area $version < hadcrut${version}${area}.txt > hadcrut${version}${area}.dat
      scp hadcrut${version}${area}.dat bhlclim:CRUData/
      egrep '^#' hadcrut${version}${area}.dat > hadcrut${version}${area}_yr.dat
      egrep -v '^#' hadcrut${version}${area}.dat | awk '{print $1 "  " $14}' >> hadcrut${version}${area}_yr.dat
      scp hadcrut${version}${area}_yr.dat bhlclim:CRUData/
    else
      echo "no change in hadcrut${version}${area}.dat"
      mv hadcrut${version}${area}.dat.old hadcrut${version}${area}.dat
    endif
  end
end
plotdat hadcrut3gl_yr.dat > hadcrut3gl_yr.txt

./makenao.sh
