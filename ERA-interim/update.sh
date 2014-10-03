#!/bin/sh
if [ "$1" = force ]; then
	force=true
else
	force=false
fi

yr=`date +%Y`
mo=`date +%m`
if [ force != true -a -f downloaded_$yr$mo ]; then
  echo "Already downloaded ERA-interim this month"
  exit
fi
./get_erainterim.py
./get_erainterim_daily.py
./update_tglobal.sh

$HOME/NINO/copyfiles.sh erai_*.nc erai_*.dat
date > downloaded_$yr$mo
