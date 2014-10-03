#!/bin/sh
vars="$1"
force=""
[ "$vars" = force ] && force=force
[ -z "$vars" -o "$vars" = force ] && vars="hgt air rhum shum uwnd vwnd"
for var in $vars
do
  file=$var.mon.mean.nc
  case $var in
  hgt) letter="z";;
  air) letter="t";;
  shum) letter="q";;
  rhum) letter="qrel";;
  uwnd) letter="u";;
  vwnd) letter="v";;
  *) echo "help";exit;;
  esac
  if [ "$force" != force ]; then
    cp $file $file.old
    wget -q -N --user=anonymous --password="oldenborgh@knmi.nl" ftp://ftp.cdc.noaa.gov/Datasets/ncep.reanalysis.derived/pressure/$file
  else
    rm -f $file.old
  fi
  cmp $file $file.old
  if [ $? != 0 -o "$force" = force ]; then
    for lev in 200 300 500 700 850
    do
      ncks -O -d level,${lev}. $file ${letter}${lev}.nc
      $HOME/NINO/copyfiles.sh ${letter}${lev}.nc
    done
  fi
  rm $file.old
done
