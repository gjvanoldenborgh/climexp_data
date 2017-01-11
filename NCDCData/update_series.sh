#!/bin/sh
yr=`date +%Y`
mo=`date +%m`
force=false
if [ "$1" = force ]; then
    force=true
fi
if [ -f downloaded_$yr$mo -a "$force" != true ]; then
  echo "Already downloaded GHCN-M this month"
  exit
fi
[ ! -d ghcnm ] && mkdir ghcnm

base=ftp://ftp.ncei.noaa.gov/pub/data/ghcn/v3
wget -q -N $base/country-codes

somethingnew=false

for element in tavg tmax tmin
do
    for type in qca qcu
    do
        file=ghcnm.$element.latest.$type.tar.gz
        wget -q -N $base/$file
        tar -zxf $file
    done
done
# get rid of version & date :-)
mv ghcnm.v3.*/* ghcnm/
for dir in ghcnm.v3.*
do
    rmdir $dir
done
cd ghcnm
for element in tavg tmax tmin
do
    for type in qca qcu
    do
        for ext in inv dat
        do
            file=`ls -t ghcnm.$element.v3.?.?.????????.$type.$ext`
            version=${file#ghcnm.$element.}
            version=${version%.$type.$ext}
            case $type in
                qca) 
                    case $element in
                        tavg) export version_mean_adj=$version;;
                        tmin) export version_min_adj=$version;;
                        tmax) export version_max_adj=$version;;
                    esac;;
                qcu) 
                    case $element in
                        tavg) export version_mean_all=$version;;
                        tmin) export version_min_all=$version;;
                        tmax) export version_max_all=$version;;
                    esac;;
            esac
            mv $file ghcnm.$element.v3.$type.$ext
            [ -f ghcnm.$element.v3.?.?.????????.$type.$ext ] && rm ghcnm.$element.v3.?.?.????????.$type.$ext
        done
    done
done
cd ..

./fillout_gettemp.sh

rsync -r -e ssh -avt ghcnm bhlclim:climexp/NCDCData/
scp gettemp gettempall \
    getmin getminall \
    getmax getmaxall \
    bhlclim:climexp/NCDCData/

date > downloaded_$yr$mo

