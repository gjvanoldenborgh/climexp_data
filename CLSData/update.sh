#!/bin/sh
ftp=ftp://ftp.cls.fr
dir=/pub/oceano/AVISO/NRT-SLA/maps/oer/merged/h
julday=`cat julday.txt`
if [ -z "$julday"]
then
  julday=18861
fi
while [ $julday -lt 20400 ]
do
  file=msla_oer_merged_h_${julday}_lr.nc.gz
  wget $ftp$dir/$file
  if [ -s $file ]
  then
    echo $julday > julday.txt
    julday=$((julday + 7))
  else
    exit
  fi
done
make cls2grads
./cls2grads
$HOME/NINO/copyfiles.sh msla_merged_1deg.???
