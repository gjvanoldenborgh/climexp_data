#!/bin/sh
yr=`date +%Y`
mo=`date +%m`
force=false
if [ -f downloaded_v2_$yr$mo -a "$force" != true ]; then
  echo "Already downloaded GHCN-M this month"
  exit
fi

base=ftp://ftp.ncdc.noaa.gov/pub/data/ghcn/v2

somethingnew=false

for file in \
    v2.prcp_adj.Z v2.prcp.Z \
    v2.slp.Z
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
  make nodup
  rm *_nodup
  ./nodup v2.mean     v2.mean_nodup
  ./nodup v2.mean_adj v2.mean_adj_nodup
  ./nodup v2.min      v2.min_nodup
  ./nodup v2.min_adj  v2.min_adj_nodup
  ./nodup v2.max      v2.max_nodup
  ./nodup v2.max_adj  v2.max_adj_nodup

  ./fillout_gettemp_v2.sh

  $HOME/NINO/copyfiles.sh v2.prcp v2.prcp_adj v2.slp
  $HOME/NINO/copyfiles.sh v2.prcp.inv.withmonth v2.prcp.adj.inv.withmonth v2.slp.inv.withmonth
  scp getprcp getprcpall getslp \
    bhlclim:climexp/bin/
fi

date > downloaded_v2_$yr$mo

