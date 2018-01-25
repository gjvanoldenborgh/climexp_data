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
useoldversion=false
if [ "$useoldversion" = true ]; then
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
else # new version
    wget -N http://crudata.uea.ac.uk/cru/data/nao/nao_3dp.dat
    cat <<EOF > nao.dat
# NAO [1] CRU North Atlantic Oscillation index
# based on Iceland and Gibraltar pressure, <a href="https://crudata.uea.ac.uk/cru/data/nao/">data description</a>
EOF
    sed -e 's/-99\.990/ -999.9/g' nao_3dp.dat >> nao.dat
fi
$HOME/NINO/copyfilesall.sh nao.dat
#
# SOI
#
if [ "$useoldversion" = true ]; then
    cp soi.dat soi.dat.old
    wget -O soi.dat.downloaded http://www.cru.uea.ac.uk/cru/data/soi/soi.dat
    cat <<EOF > soi.dat
# SOI (Southern Oscillation Index) from CRU
# <a href="https://crudata.uea.ac.uk/cru/data/soi/">data description</a>
EOF
    sed -e 's/-10\.00/-999.9/g' -e 's/-99\.99/-999.9/g' soi.dat.downloaded >> soi.dat
    diff soi.dat soi.dat.old
    if [ $? != 0 ]; then
        rm soi.dat.old
        filtermonthseries lo box 5 soi.dat > soi5.dat
        $HOME/NINO/copyfilesall.sh soi.dat soi5.dat
    else
        echo "soi.dat has not changed"
        mv soi.dat.old soi.dat
    fi
else # new version
    cp soi.dat soi.dat.old
    wget -N http://crudata.uea.ac.uk/cru/data/soi/soi_3dp.dat
    cat <<EOF > soi.dat
# <a href="https://crudata.uea.ac.uk/cru/data/soi/">data description</a>
# institution :: UAE/CRU
# link :: https://crudata.uea.ac.uk/cru/data/soi/
# history :: retrieved from AUE/CRU on `date`
# SOI [1] CRU Southern Oscillation Index
EOF
    sed -e 's/-99\.990/ -999.9/g' soi_3dp.dat >> soi.dat
    diff soi.dat soi.dat.old
    if [ $? != 0 ]; then
        rm soi.dat.old
        filtermonthseries lo box 5 soi.dat > soi5.dat
        $HOME/NINO/copyfilesall.sh soi.dat soi5.dat
    else
        echo "soi.dat has not changed"
        mv soi.dat.old soi.dat
    fi
fi
$HOME/copyfilesall.sh soi.dat soi5.dat

./makenao.sh
