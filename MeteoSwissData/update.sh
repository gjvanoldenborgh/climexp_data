#!/bin/sh
base=http://www.meteoswiss.admin.ch/product/input/climate-data/swissmean/
version=10.18751-Climate-Timeseries-CHTM-1.0
for region in swiss north.low north.high south
do
    wget -q -N ${base}${version}-$region.txt
    egrep -v '^[12]' ${version}-$region.txt | fgrep -v 'djf' | tr -d '\r' | egrep -v '^[ \t]*$' \
        | sed -e 's/^/# /' -e 's/: / :: /' -e 's/DOI: /doi:/' -e 's/Federal/institution :: Federal/' \
        -e 's/Area/title :: Area/' > swiss_$region.dat
    echo "# T [Celsius] Swiss ${region}-averaged temperature" >> swiss_$region.dat
    egrep '^[12]'  ${version}-$region.txt | cut -f 1-13 -d '	' | sed -e 's/NA/-999.9/g' >> swiss_$region.dat
done
$HOME/NINO/copyfiles.sh swiss_*.dat