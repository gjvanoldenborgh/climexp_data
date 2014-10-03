#!/bin/sh

# CRU TS

vers=cru_ts3.22
vars="tmp tmn tmx dtr pre vap cld"

    for var in $vars
    do
        f=`echo $vers.1901.2*.$var.dat.nc`
        if [ ! -s $f ]; then
            zfile=$vers.1901.2*.$var.dat.nc.gz
            echo "uncompressing $zfile"
            file=${zfile%.gz}
            [ -f $file ] && rm $file
            gunzip -f $zfile
        fi
        f=`echo $f`
        c=`file $f | fgrep -c -i Hierarchical`
        if [ $c = 0 ]; then
            echo "recompressing $file"
            cdo -r -f nc4 -z zip copy $f aap.nc
            mv aap.nc $f
        fi

        f1=${f%.nc}_1.nc
        echo "generating $f1"
        averagefieldspace $f 2 2 $f1
        cdo -r -f nc4 -z zip copy $f1 aap.nc
        mv aap.nc $f1

        f25=${f%.nc}_25.nc
        echo "generating $f25"
        averagefieldspace $f 5 5 $f25
        cdo -r -f nc4 -z zip copy $f25 aap.nc
        mv aap.nc $f25
        
        echo "copying"
        $HOME/NINO/copyfiles.sh $f $f1 $f25
    done
    mail -s "new version CRU TS!" oldenborgh@knmi.nl <<EOF
New version $version of CRU TS has been downloaded, please adjust queryfield.cgi and selectfield_obs.html
EOF

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
