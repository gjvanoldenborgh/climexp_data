#!/bin/bash

# ESRL AGGI

base=https://www.esrl.noaa.gov/gmd/aggi
file=AGGI_Table.csv
wget -N --no-check-certificate $base/$file

vars=`head -n 1 $file`
col=1
while [ $col -lt 10 ]; do
    ((col++))
    total1=true
    var=`echo $vars | cut -d ',' -f $col`
    case $var in
        CO2|CH4|N2O|CFC12|CFC11|15-minor|Total)
            if [ $var != Total -o total1 = true ]; then
                [ $var = Total ] && total1=false
                name="$var radiative forcing"
                units='W/m2'
            elif [ $var = Total ]; then
                var="CO2eq"
                name='equivalent CO2 concentration'
                units="ppm"
            else
                echo "$0: error bcdfhh"; exit -1
            fi;;
        1990*)
            var=AGGI
            name='annual greenhouse gas index'
            units='1'
            ;;
        *) echo "$0: error: unknown var $var";exit -1;;
    esac

    outfile=${var}_noaa.dat
    cat > $outfile <<EOF
# Radiative forcings and annual greenhouse gas index from <a href="https://www.esrl.noaa.gov/gmd/aggi/aggi.html">NOAA</a>
# $var [$units] $name
# institution :: NOAA/ESRL
# source_url :: $base/$file
# source :: https://www.esrl.noaa.gov/gmd/aggi/aggi.html
# contact :: James.H.Butler@noaa.gov
# climexp_url :: https://climexp.knmi.nl/getindices.cgi?NOAAData/$outfile
EOF
    tail -n +2 $file | cut -d ',' -f 1,$col | tr ',' ' ' >> $outfile
done 
$HOME/NINO/copyfilesall.sh *_noaa.dat

# MEI

cp meiv2.data meiv2.data.old
url=https://www.esrl.noaa.gov/psd/enso/mei/data/meiv2.data
wget --no-check-certificate -N $url
cat > meiv2.dat <<EOF
# MEI [1] Multivariate ENSO Index v2
# shifted by 0.5 month, i.e., the Jan value represents the Dec/Jan MEI index.
# from <a href="https://www.esrl.noaa.gov/psd/enso/mei/">ESRL</a>
# insitution :: NOAA/ESRL
# link :: https://www.esrl.noaa.gov/psd/enso/mei/
# source :: $url
# history :: retrieved from NOAA/ESRL on `date`
EOF
tail -n +2 meiv2.data | egrep '^[12][0-9]' | sed -e 's/-999.00/ -999.9/g' >> meiv2.dat
$HOME/NINO/copyfiles.sh meiv2.dat

if [ -n "$MEI_UPDATED_AGAIN" ]; then
cp table.html table.html.old
url=https://www.esrl.noaa.gov/psd/enso/mei/table.html
wget -N $url
cat > mei.dat <<EOF
# MEI [1] Multivariate ENSO Index
# shifted by 0.5 month, i.e., the Jan value represents the Dec/Jan MEI index.
# from <a href="https://www.esrl.noaa.gov/psd/enso/mei/">ESRL</a>
# insitution :: NOAA/ESRL
# author :: Klaus Wolters
# link :: https://www.esrl.noaa.gov/psd/enso/mei/
# source :: $url
# history :: retrieved from NOAA/ESRL on `date`
EOF
egrep '^[12][0-9]' table.html >> mei.dat
lastline=`tail -1 mei.dat`
ndef=`echo $lastline | wc -w`
ndef=$((ndef - 1))
nundef=$((12 - ndef))
undef=""
while [ $nundef -gt 0 ]; do
  undef="$undef -999.9"
  nundef=$((nundef - 1))
done
sed -e "s/$lastline/$lastline $undef/" mei.dat > aap.dat
mv aap.dat mei.dat
$HOME/NINO/copyfiles.sh mei.dat

fi # MEI

# OLR

cp olr.mon.mean.nc olr.mon.mean.nc.old
wget -N ftp://ftp.cdc.noaa.gov/Datasets/interp_OLR/olr.mon.mean.nc
describefield olr.mon.mean.nc
$HOME/NINO/copyfiles.sh olr.mon.mean.nc
