#!/bin/sh
force=false
#
# global and hemispheric temperatures
#
for version in 4 4v # 3 3v
do
  for area in gl sh nh; do
    file=CRUTEM${version}-${area}.dat
    cp $file $file.old
    wget -N http://www.cru.uea.ac.uk/cru/data/temperature/$file
    diff $file $file.old
    if [ "$force" = true -o $? != 0 ]; then
      mv crutem${version}${area}.dat crutem${version}${area}.dat.old
      ./dat2dat $area $version CRUTEM < $file > crutem${version}${area}.dat
      $HOME/NINO/copyfiles.sh crutem${version}${area}.dat
      egrep '^#' crutem${version}${area}.dat > crutem${version}${area}_yr.dat
      egrep -v '^#' crutem${version}${area}.dat | awk '{print $1 "  " $14}' >> crutem${version}${area}_yr.dat
      $HOME/NINO/copyfiles.sh crutem${version}${area}_yr.dat
    else
      echo "no change in $file"
      mv $file.old $file
    fi
  done
done

#
# NAO
#
rm nao.dat
mv nao_base.dat nao.dat
wget -N http://www.cru.uea.ac.uk/cru/data/nao/nao.dat
mv nao.dat nao_base.dat
cp nao_update.htm nao_update.htm.old
wget -N http://www.cru.uea.ac.uk/~timo/datapages/naoi.htm
###make update_nao
cat > nao.dat <<EOF
# Normalised NAO index from pressure readings in Iceland and Gibraltar
# Source: <a href="http://www.cru.uea.ac.uk/cru/data/nao/">CRU</a>, updated by <a href="http://www.cru.uea.ac.uk/~timo/datapages/naoi.htm">Tim Osborn</a>
# NAO [1] North Atlantic Oscillation index
EOF
./update_nao >> nao.dat
patchseries nao.dat $HOME/NINO/NCEPData/cpc_nao.dat > nao_combined.dat
$HOME/NINO/copyfilesall.sh nao.dat nao_combined.dat
#
# SOI
#
cp soi.dat soi.dat.old
wget -O soi.dat.downloaded http://www.cru.uea.ac.uk/cru/data/soi/soi.dat
cat <<EOF > soi.dat
# SOI (Southern Oscillation Index) from CRU
# <a href="http://www.cru.uea.ac.uk/cru/data/soi.htm">data description</a>
EOF
sed -e 's/-10\.00/-999.9/g' -e 's/-99\.99/-999.9/g' soi.dat.downloaded >> soi.dat
diff soi.dat soi.dat.old
if [ $? != 0 ]; then
    rm soi.dat.old
    $HOME/NINO/Fortran/filtermonthseries lo box 5 soi.dat > soi5.dat
    $HOME/NINO/copyfilesall.sh soi.dat soi5.dat
else
    echo "soi.dat has not changed"
    mv soi.dat.old soi.dat
fi

./makenao.sh
