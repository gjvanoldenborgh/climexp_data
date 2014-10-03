#!/bin/sh
for tree in REANALYSES
do
    wget -N --user=anonymous --password=oldenborgh@knmi.nl -r -l 10 --reject '*_mon*' ftp://ftp.cccma.ec.gc.ca/data/climdex/$tree
done

for tree in CMIP5 # CMIP3 REANALYSES
do
    for scenario in historical rcp45
    do
        ###wget -N --user=anonymous --password=oldenborgh@knmi.nl -r -l 10 --reject '*_mon*' --reject '*_alt*' ftp://ftp.cccma.ec.gc.ca/data/climdex/$tree/$scenario
        wget -N --user=anonymous --password=oldenborgh@knmi.nl -r -l 10 --reject '*_mon*' --accept '*altcdd*' --accept '*_altcwd' ftp://ftp.cccma.ec.gc.ca/data/climdex/$tree/$scenario
    done
done
