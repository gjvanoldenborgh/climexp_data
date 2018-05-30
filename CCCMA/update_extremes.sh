#!/bin/sh
for tree in CMIP5 # CMIP3 REANALYSES
do
    for scenario in rcp26 rcp60 rcp85 # historical rcp45 # historicalGHG # 
    do
        ###wget -N --user=anonymous --password=oldenborgh@knmi.nl -r -l 10 --reject '*_mon*' --reject '*_alt*' ftp://ftp.cccma.ec.gc.ca/data/climdex/$tree/$scenario
        wget -N --user=anonymous --password=oldenborgh@knmi.nl -r -l 10 --reject '*_mon*' --accept '*tr*' ftp://ftp.cccma.ec.gc.ca/data/climdex/$tree/$scenario
    done
done

echo "Skipping reanalyses"
exit
for tree in REANALYSES
do
    wget -N --user=anonymous --password=oldenborgh@knmi.nl -r -l 10 --reject '*_mon*' ftp://ftp.cccma.ec.gc.ca/data/climdex/$tree
done

