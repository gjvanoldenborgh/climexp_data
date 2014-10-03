#!/bin/sh
for type in amo nino3 pdo nh sst
do
    case $type in
	amo) name="AMO";long_name="AMO";units="1";;
	pdo) name="PDO";long_name="PDO";units="1";;
	nino3) name="Nino3";long_name="Nino3";units="1";;
	nh) name="NH";long_name="NH temperature";units="K";;
	sst) name="SST";long_name="Global SST";units="K";;
    esac
    wget -N ftp://ftp.ncdc.noaa.gov/pub/data/paleo/contributions_by_author/mann2009b/${type}all.txt
    cat > ${type}_mann.dat <<EOF
# ${name} [${units}] ${long_name} reconstruction
# Mann et al, Science 2009 (326) 1256-1260 doi:10.1126/science.1177303
# 1850-2006 PC-filtered instrumental observations.
# <a href="http://www.ncdc.noaa.gov/paleo/pubs/mann2009b/mann2009b.html">documentation</a>
EOF
    cat ${type}all.txt | awk '{print $1 " " $2}' >> ${type}_mann.dat
done

wget -N  ftp://ftp.ncdc.noaa.gov/pub/data/paleo/drought/pdsi2004/dai.txt
make dai2dat
./dai2dat > dai.dat

wget -N ftp://ftp.ncdc.noaa.gov/pub/data/paleo/treering/reconstructions/nao-trouet2009.txt
make naoms2dat
./naoms2dat > nao_trouet.dat

wget -N ftp://ftp.ncdc.noaa.gov/pub/data/paleo/treering/reconstructions/pdo-macdonald2005.txt
make pdom2dat
./pdom2dat > pdo_macdonald.dat

wget -N ftp://ftp.ncdc.noaa.gov/pub/data/paleo/treering/reconstructions/enso-li2011.txt
make ensol2dat
./ensol2dat > enso_li.dat


$HOME/NINO/copyfiles.sh dai.dat nao_trouet.dat pdo_macdonald.dat enso_li.dat *_mann.dat
