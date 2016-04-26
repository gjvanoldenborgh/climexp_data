#!/bin/sh
if [ "$1" = force ]; then
	force=true
else
	force=false
fi

yr=`date +%Y`
mo=`date +%m`
if [ $force != true -a -f downloaded_$yr$mo ]; then
  echo "Already downloaded ERA-interim this month"
  exit
fi
if [ 1 = 1 ]; then
./get_erainterim.py
./get_erainterim_daily.py
./update_tglobal.sh
./update_twetbulb.sh
$HOME/NINO/copyfiles.sh erai_*.nc erai_*.dat
fi


for var in txx tnn rx1day rx3day rx5day
do
    case $var in
        txx) basevar=tmax;oper=max;;
        tnn) basevar=tmin;oper=min;;
        rx1day) basevar=tp;oper=max;;
        rx3day) basevar=tp;oper="max sum 3";;
        rx5day) basevar=tp;oper="max sum 5";;
        *) echo "$0: unknown var $var"; exit -1;;
    esac
    echo "Computing $var on zuidzee"
    rsync erai_${basevar}_daily.nc zuidzee:NINO/ERA-interim/
    ssh zuidzee "cd NINO/ERA-interim; daily2longerfield erai_${basevar}_daily.nc 1 $oper minfac 75 erai_$var.nc"
    rsync zuidzee:NINO/ERA-interim/erai_$var.nc .
    $HOME/NINO/copyfiles.sh erai_$var.nc
done

date > downloaded_$yr$mo
