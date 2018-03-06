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
    case $abbrv in
        aao) source=http://www.cpc.noaa.gov/products/precip/CWlink/daily_ao_index/aao/aao.shtml;;
        ao)  source=http://www.cpc.noaa.gov/products/precip/CWlink/daily_ao_index/ao.shtml;;
        nao) source=http://www.cpc.noaa.gov/products/precip/CWlink/pna/nao.shtml;;
        pna) source=http://www.cpc.noaa.gov/products/precip/CWlink/pna/pna.shtml;;
    esac
    cat > cpc_${abbrv}_daily.dat <<EOF
# CPC <a href="http://www.cpc.noaa.gov/products/precip/CWlink/daily_ao_index/teleconnections.shtml">$abbrv</a> index
# $abbrv [1] $abbrv index
# institution :: NOAA/NCEP/CPC
# source_url :: ftp://ftp.cpc.ncep.noaa.gov/cwlinks/
# referemces :: $source
# history :: retrieved `date`
# climexp_url :: https://climexp.knmi.nl/getindices.cgi?NCEPData/cpc_${abbrv}_daily
EOF
    sed -e '/-0.99900E+34/d' -e '/\*/d' $file >> cpc_${abbrv}_daily.dat
    $HOME/NINO/copyfiles.sh cpc_${abbrv}_daily.dat
  fi
done

