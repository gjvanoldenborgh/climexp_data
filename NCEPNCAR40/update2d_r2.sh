#!/bin/sh

base=http://nomad3.ncep.noaa.gov/pub/reanalysis-2/month/flx/
wget='wget -q --user=anonymous --password="oldenborgh@knmi.nl"'

mv flx.ctl flx.ctl.old
$wget -N $base/flx.ctl
if [ ! -s flx.ctl ]; then
  echo "Cannot get flx.ctl, giving up.  Please retry later"
  mv flx.ctl.old flx.ctl
  exit -1
fi
cp flx.ft06.197901.avrg.grib.idx flx.ft06.197901.avrg.grib.idx.old
$wget -N $base/flx.ft06.197901.avrg.grib.idx
if [ ! -s flx.ft06.197901.avrg.grib.idx ]; then
  echo "Cannot get flx.ft06.197901.avrg.grib.idx; giving up.  Please retry later"
  mv flx.ft06.197901.avrg.grib.idx.old flx.ft06.197901.avrg.grib.idx
  exit -1
fi

yr=1979
mo=0
nt=0
found=true
while [ $found = true ]
do
  nt=$((nt + 1))
  mo=$(($mo + 1))
  if [ $mo -gt 12 ]; then
    mo=1
    yr=$(($yr + 1))
  fi
  if [ $mo -lt 10 ]; then
    yyyymm=${yr}0${mo}
  else
    yyyymm=${yr}${mo}
  fi
  file=flx.ft06.${yyyymm}.avrg.grib
  cp $file $file.old
  $wget -N $base/$file
  cmp $file $file.old
  if [ $? = 0 ]; then
    found=true
  elif [ -s $file ]; then
    $wget -N $base/$file.inv
    found=true
  else
    found=false
  fi
  rm $file.old
done
nt=$(($nt - 1))
mo=$(($mo - 1))
if [ $mo -le 0 ]; then
  mo=12
  yr=$(($yr - 1))
fi
months[0]="???"
months[1]="jan"
months[2]="feb"
months[3]="mar"
months[4]="apr"
months[5]="may"
months[6]="jun"
months[7]="jul"
months[8]="aug"
months[9]="sep"
months[10]="oct"
months[11]="nov"
months[12]="dec"
months[13]="???"
date=${months[$mo]}$yr
echo $date

for var in t2m prcp dswrfsfc dlwrfsfc
do
  case $var in
  t2m) 
    gribvar=TMP2m
    oper="-273.15"
    lvar="2m temperature [C]";;
  prcp) 
    gribvar=PRATEsfc
    oper=""
    lvar="surface precipitation [kg/m2/s]";;
  dswrfsfc)
    gribvar=DSWRFsfc
    oper=""
    lvar="surface downward shortwave radiation [W/m2]";;
  dlwrfsfc)
    gribvar=DLWRFsfc
    oper=""
    lvar="surface downward longwave radiation [W/m2]";;
  *) echo "please specify netcdf file for R1 part for var $var";exit -1;;
  esac
  grads -l -b <<EOF
open flx.ctl
set time jan1979 $date
set x 1 192
set gxout fwrite
set fwrite n$var.dat
d $gribvar$oper
disable fwrite
quit
EOF
  cat > n$var.ctl << EOF
DSET ^n$var.dat
TITLE NCEP/DOE R2 1979-$date reanalysis
UNDEF -9.99e8
OPTIONS little_endian
XDEF 192 LINEAR 0.000000 1.875
YDEF 94 LEVELS
 -88.542 -86.653 -84.753 -82.851 -80.947 -79.043 -77.139 -75.235 -73.331 -71.426
 -69.522 -67.617 -65.713 -63.808 -61.903 -59.999 -58.094 -56.189 -54.285 -52.380
 -50.475 -48.571 -46.666 -44.761 -42.856 -40.952 -39.047 -37.142 -35.238 -33.333
 -31.428 -29.523 -27.619 -25.714 -23.809 -21.904 -20.000 -18.095 -16.190 -14.286
 -12.381 -10.476  -8.571  -6.667  -4.762  -2.857  -0.952   0.952   2.857   4.762
   6.667   8.571  10.476  12.381  14.286  16.190  18.095  20.000  21.904  23.809
  25.714  27.619  29.523  31.428  33.333  35.238  37.142  39.047  40.952  42.856
  44.761  46.666  48.571  50.475  52.380  54.285  56.189  58.094  59.999  61.903
  63.808  65.713  67.617  69.522  71.426  73.331  75.235  77.139  79.043  80.947
  82.851  84.753  86.653  88.542
ZDEF 1 LINEAR 0 1
TDEF $nt LINEAR 15JAN1979 1MO
VARS 1
$var 0 99 $lvar
ENDVARS
EOF
  $HOME/NINO/copyfiles.sh n$var.dat n$var.ctl
done
rm nprcp.new.ctl nprcp.new.dat
./prcp2mm nprcp.ctl
$HOME/NINO/copyfiles.sh nprcp.new.dat nprcp.new.ctl
