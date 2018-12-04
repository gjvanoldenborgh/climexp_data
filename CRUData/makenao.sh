#!/bin/sh
cp nao_azo.dat nao_ice.dat old/
for file in nao_ice.dat nao_azo.dat
do
    wget --no-check-certificate -N http://www.cru.uea.ac.uk/cru/data/nao/$file
    newfile=`basename $file .dat`_new.dat
    cat > $newfile <<EOF
# source :: http://www.cru.uea.ac.uk/cru/data/nao/$file
# institution :: UEA/CRU
# history :: downloaded on `date`
EOF
    tail -n +2 $file | sed -e 's/  -10/-999.9/g' >> $newfile
done
normdiff nao_azo_new.dat nao_ice_new.dat yearly yearly > nao_ijs_azo.dat
