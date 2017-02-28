#!/bin/sh
# get CRU TS
force=false
if [ "$1" = force ]; then
    force=true
fi

vars="tmp tmn tmx dtr pre vap cld"
version="3.24.01"
vers=cru_ts$version
date=1701201703
last=2015
base=https://crudata.uea.ac.uk/cru/data/hrg/cru_ts_$version/
###ftp ftp1.ceda.ac.uk < commands.ftp > ftp.lo1

for var in $vars
do
    for kind in dat stn st0; do
        doit=true
        case $kind in
            dat) dir=cruts.$date.v$version;;
            stn|st0) dir=station.$date.v$version
                if [ $var = tmn -o $var = tmx -o $var = cld ]; then
                    doit=false
                fi;;
            *) echo "$0: unknown kind $kind"; exit -1;;
        esac
        if [ $doit = true ]; then
            file=$vers.1901.$last.$var.$kind.nc
            if [ ! -s $file ]; then
                mkdir -p $var
                echo "downloading $var $kind ..."
                (cd $var; wget -q --no-check-certificate -N $base/$dir/$var/$file.gz)
                if [ ! -s $var/$file.gz ]; then
                    echo "Something went wrong in downloading $base/$dir/$var/$file.gz"
                    exit -1
                fi
                echo "uncompressing $file.gz"
                [ -f $file ] && rm $file
                (cd $var; gunzip -f $file.gz)

                echo "recompressing $file"
                cdo -r -f nc4 -z zip copy $var/$file $file
                rm $var/$file
            fi
        fi
    done
    f=$vers.1901.$last.$var.dat.nc
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
    $HOME/NINO/copyfiles.sh $f $f1 $f25
done