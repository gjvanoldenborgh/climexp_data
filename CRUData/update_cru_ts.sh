#!/bin/sh
# get CRU TS
force=false
if [ "$1" = force ]; then
    force=true
fi

vars="tmp tmn tmx dtr pre vap cld"
version="4.01"
vers=cru_ts$version
date=1709081022
last=2016
base=https://crudata.uea.ac.uk/cru/data/hrg/cru_ts_$version/
###ftp ftp1.ceda.ac.uk < commands.ftp > ftp.lo1

for var in $vars
do
    dir=cruts.$date.v$version
    file=$vers.1901.$last.$var.dat.nc
    sfile=$vers.1901.$last.$var.stn.nc
    if [ ! -s $file ]; then
        mkdir -p $var
        echo "downloading $var ..."
        (cd $var; wget -q --no-check-certificate -N $base/$dir/$var/$file.gz)
        if [ ! -s $var/$file.gz ]; then
            echo "Something went wrong in downloading $base/$dir/$var/$file.gz"
            exit -1
        fi
        echo "uncompressing $file.gz"
        [ -f $file ] && rm $file
        (cd $var; gunzip -f $file.gz)

        echo "recompressing $file"
        cdo -r -f nc4 -z zip selvar,$var $var/$file $file
        cdo -r -f nc4 -z zip selvar,stn $var/$file $sfile
        ncatted -a missing_value,stn,c,f,-999. $sfile
        rm $var/$file
    fi
    . $HOME/climexp/add_climexp_url_field.cgi
    f=$file
    f1=${f%.nc}_1.nc
    if [ ! -f $f1 ]; then
        echo "generating $f1"
        averagefieldspace $f 2 2 $f1
    fi
    f25=${f%.nc}_25.nc
    if [ ! -f $f25 ]; then
        echo "generating $f25"
        averagefieldspace $f 5 5 $f25
    fi
    echo "copying"
    $HOME/NINO/copyfiles.sh $f $f1 $f25 $sfile
done