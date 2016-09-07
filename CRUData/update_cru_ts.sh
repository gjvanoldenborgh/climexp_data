#!/bin/sh
# get CRU TS
force=false
if [ "$1" = force ]; then
    force=true
fi

vars="tmp tmn tmx dtr pre vap cld"

ftp ftp1.ceda.ac.uk <<EOF > ftp.log
cd badc/cru/data/cru_ts
dir 
quit
EOF

cp version.txt version.txt.old
fgrep cru_ts_ ftp.log | awk '{print $9}' | fgrep -v '_clim' | sort | tail -1 > version.txt
diff version.txt.old version.txt
if [ $? != 0 -o $force = true ]; then
    version=`cat version.txt`
    vers=`echo $version | sed -e 's/ts_/ts/'`
    cat <<EOF > commands.ftp
cd badc/cru/data/cru_ts/$version/data
prompt
EOF
    for var in $vars
    do
        case $var in
            tmn|tmx|dtr) altvar=tmpdtr;;
            *) altvar=$var
        esac
        [ ! -d $var ] && mkdir $var
        f=`echo $vers.1901.2*.$var.dat.nc`
        if [ ! -s $f -o $force = true ]; then
            cat <<EOF >> commands.ftp
mget $var/$vers.1901.2*.$var.dat.nc.gz
cd ../station
mget $var/$vers.1901.2*.$altvar.st0.nc.gz
mget $var/$vers.1901.2*.$altvar.stn.nc.gz
cd ../data
EOF
        fi
    done
    echo 'quit' >> commands.ftp
    echo "downloading data ..."
    ###ftp ftp1.ceda.ac.uk < commands.ftp > ftp.lo1

    for var in $vars
    do
        for kind in dat stn st0; do
            f=`echo $vers.1901.2*.$var.$kind.nc`
            if [ ! -s $f ]; then
                zfile=$var/$vers.1901.2*.$var.$kind.nc.gz
                echo "uncompressing $zfile"
                file=${zfile%.gz}
                [ -f $file ] && rm $file
                gunzip -f $zfile

                echo "recompressing $file"
                f=`basename $file`
                cdo -r -f nc4 -z zip copy $file $f
                rm $file
            fi
        done
    done
    mail -s "new version CRU TS!" oldenborgh@knmi.nl <<EOF
New version $version of CRU TS has been downloaded, please adjust queryfield.cgi and selectfield_obs.html
EOF
fi # action necessary?
for var in $vars; do
    f=`echo $vers.1901.2*.$var.dat.nc`
    f1=${f%.nc}_1.nc
    if [ ! -f $f1 ]; then
        echo "generating $f1"
        averagefieldspace $f 2 2 $f1
        cdo -r -f nc4 -z zip copy $f1 aap.nc
        mv aap.nc $f1
    fi
    f25=${f%.nc}_25.nc
    if [ ! -f $f25 ]; then
        echo "generating $f25"
        averagefieldspace $f 5 5 $f25
        cdo -r -f nc4 -z zip copy $f25 aap.nc
        mv aap.nc $f25
    fi
    echo "copying"
    $HOME/NINO/copyfiles.sh $f $f1 $f25
done


exit 
# old version

make ts32grads
for var in vap # tmp tmn tmx dtr pre vap
do
  file=cru_ts_3_00.1901.2006.$var.dat
  if [ $file.dat.gz -nt $file ]; then
    gunzip -c $file.dat.gz > $file
  fi
  ts32grads 1 $file
  ts32grads 2 $file
###  rm $file
done
