#!/bin/sh
for tree in CMIP5 # CMIP3 REANALYSES
do
    for scenario in historicalGHG # historical rcp45
    do
        ###wget -N --user=anonymous --password=oldenborgh@knmi.nl -r -l 10 --reject '*_mon*' --reject '*_alt*' ftp://ftp.cccma.ec.gc.ca/data/climdex/$tree/$scenario
        wget -N --user=anonymous --password=oldenborgh@knmi.nl -r -l 10 --reject '*_mon*' --accept '*rx1day*' ftp://ftp.cccma.ec.gc.ca/data/climdex/$tree/$scenario
    done
done

echo "Skipping reanalyses"
exit
for tree in REANALYSES
do
    wget -N --user=anonymous --password=oldenborgh@knmi.nl -r -l 10 --reject '*_mon*' ftp://ftp.cccma.ec.gc.ca/data/climdex/$tree
done

