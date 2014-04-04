#!/bin/sh
# daily indices
for file in norm.daily.aao.index.b790101.current.ascii norm.daily.ao.index.b500101.current.ascii norm.daily.nao.index.b500101.current.ascii norm.daily.pna.index.b500101.current.ascii
do
  cp $file $file.old
  wget -q -N ftp://ftp.cpc.ncep.noaa.gov/cwlinks/$file
  diff $file $file.old
  if [ $? != 0 -o "$1" = force ]; then
    abbrv=${file#norm.daily.}
    abbrv=${abbrv%%\.*}
    cat > cpc_${abbrv}_daily.dat <<EOF
# CPC <a href="ftp://ftp.cpc.ncep.noaa.gov/cwlinks/">$abbrv</a> index
# $abbrv [1] $abbrv index
EOF
    sed -e '/-0.99900E+34/d' -e '/\*/d' $file >> cpc_${abbrv}_daily.dat
  fi
  $HOME/NINO/copyfiles.sh cpc_${abbrv}_daily.dat
done

