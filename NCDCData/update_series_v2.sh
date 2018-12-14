#!/bin/bash
yr=`date +%Y`
mo=`date +%m`
force=false
if [ "$1" = force ]; then
    force=true
fi
if [ -f downloaded_v2_$yr$mo -a "$force" != true ]; then
  echo "Already downloaded GHCN-M this month"
  exit
fi

base=ftp://ftp.ncdc.noaa.gov/pub/data/ghcn/v2

if [ ! -s v2.slp -o ! -s v2.slp.inv ]; then
    echo "$0: error: v2.slp and v2.slp.inv should be procured elsewhere"
    exit -1
fi

somethingnew=false

wget -q -N $base/v2.prcp.inv
wget -q -N $base/v2.country.codes
for file in \
    v2.prcp_adj.Z v2.prcp.Z # v2.slp.Z no longer exists at NCEI, last update was 2003, but we still offer an old version
do
    cp $file $file.old
    wget -q -N $base/$file
    cmp $file $file.old
    if [ $? != 0 ]; then
      somethingnew=true
      f=`basename $file .Z`
      gunzip -c $file > $f
    fi
done

if [ $somethingnew = true -o "$force" = true ]; then

  export date=`date`
  ./fillout_gettemp_v2.sh

  $HOME/NINO/copyfiles.sh v2.prcp v2.prcp_adj v2.slp
  $HOME/NINO/copyfiles.sh v2.prcp.inv.withmonth v2.prcp.adj.inv.withmonth v2.slp.inv.withmonth
  $HOME/NINO/copyfiles.sh getprcp getprcpall getslp
fi

date > downloaded_v2_$yr$mo

