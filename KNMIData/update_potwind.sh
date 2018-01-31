#!/bin/sh

mkdir -p tmp_potwind
DEBUG=false
if [ "$DEBUG" != true ]; then
    wget=wget
    unzip=unzip
else
    echo "DEBUG, NO DATA RETRIEVED"
    wget="echo wget"
    unzip="echo unzip"
fi

# new data
base=http://projects.knmi.nl/klimatologie/onderzoeksgegevens/potentiele_wind-sigma/
$wget -O list.html $base
files=`fgrep .zip list.html | sed -e 's/^.*href=["]//' -e 's/["].*$//'`

for file in $files; do
    $wget -q -N $base$file
done

# old data
base=http://projects.knmi.nl/klimatologie/onderzoeksgegevens/potentiele_wind/up_upd/
histfile=20140307_update_up.zip
$wget -q -N $base/$histfile

cd tmp_potwind
for file in ../potwind*.zip; do
    $unzip -o $file
done
$unzip -o ../$histfile
cd ..


stations=`ls tmp_potwind | sed -e 's/potwind_//' -e 's/_.*$//' | sort | uniq`
nstations=`echo $stations | wc -w`
cat > list_upx.txt <<EOF
located $nstations stations in 50.0N:56.5N, 1.5E:8.0E
EOF
for station in $stations; do
    if [ ! -s latlon_wind$station.txt ]; then
        if [ ! -x RDNAPTRANS2008/rdnaptrans2008 ]; then
            cd RDNAPTRANS2008
            c++ -o rdnaptrans2008 rdnaptrans2008.cpp
            cd ..
        fi
        if [ ! -x RDNAPTRANS2008/rdnaptrans2008 ]; then
            echo "Please compile rdnaptrans2008.cpp"
            exit -1
        fi
        lastfile=`ls tmp_potwind/potwind_${station}_???? | tail -n 1`
        line=`fgrep COORDINATES $lastfile`
        x=`echo $line | sed -e 's/^.*X ://' -e 's/;.*$//'`
        y=`echo $line | sed -e 's/^.*Y ://'`
        cd RDNAPTRANS2008
        ./rdnaptrans2008 <<EOF > ../aap.txt
2
$x
$y
0
0
EOF
        cd ..
        lat=`cat aap.txt | fgrep phi | sed -e 's/phi *//'`
        lon=`cat aap.txt | fgrep lambda | sed -e 's/lambda *= *//'`
        cat > latlon_wind$station.txt <<EOF
$station
$lat N
$lon E
EOF
    fi
    ./txt2dat_potwind tmp_potwind/potwind_${station}_???? >> list_upx.txt
    gzip -c upx$station.dat > upx$station.gz
done
echo "==============================================" >> list_upx.txt
$HOME/NINO/copyfiles.sh upx* list_upx.txt
