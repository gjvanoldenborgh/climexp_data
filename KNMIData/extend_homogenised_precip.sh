#!/bin/sh
#
# attach real-time data from the 8-8 network to Adri's homogenised precipitation dataset 
# that only runs up to 2009.
#
for file in precip???_hom_1910-2009.dat.gz precip???_hom_1951-2009.dat.gz
do
    id=${file#precip}
    id=${id%%_*}
    oper=rr$id.gz
    if [ -s $oper ]; then
        newfile=${file%-2009.dat.gz}.dat
        newfile=`echo $newfile | tr -d '_'`
        if [ $newfile -ot $oper ]; then
            echo "# extended with operational data from KNMI 2010-now" > $newfile
            zcat $file >> $newfile
            zcat $oper | egrep '^20[1234]' >> $newfile
            gzip -f $newfile
        fi
    fi
done
rsync precip???hom19??.dat.gz bhlclim:climexp/KNMIData/